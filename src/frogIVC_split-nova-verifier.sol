// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

/*
    Sonobe's Nova + CycleFold decider verifier.
    Joint effort by 0xPARC & PSE.

    More details at https://github.com/privacy-scaling-explorations/sonobe
    Usage and design documentation at https://privacy-scaling-explorations.github.io/sonobe-docs/

    Uses the https://github.com/iden3/snarkjs/blob/master/templates/verifier_groth16.sol.ejs
    Groth16 verifier implementation and a KZG10 Solidity template adapted from
    https://github.com/weijiekoh/libkzg.
    Additionally we implement the NovaDecider contract, which combines the
    Groth16 and KZG10 verifiers to verify the zkSNARK proofs coming from
    Nova+CycleFold folding.
*/


/* =============================== */
/* KZG10 verifier methods */
/**
 * @author  Privacy and Scaling Explorations team - pse.dev
 * @dev     Contains utility functions for ops in BN254; in G_1 mostly.
 * @notice  Forked from https://github.com/weijiekoh/libkzg.
 * Among others, a few of the changes we did on this fork were:
 * - Templating the pragma version
 * - Removing type wrappers and use uints instead
 * - Performing changes on arg types
 * - Update some of the `require` statements 
 * - Use the bn254 scalar field instead of checking for overflow on the babyjub prime
 * - In batch checking, we compute auxiliary polynomials and their commitments at the same time.
 */
contract KZG10Verifier {

    // prime of field F_p over which y^2 = x^3 + 3 is defined
    uint256 public constant BN254_PRIME_FIELD =
        21888242871839275222246405745257275088696311157297823662689037894645226208583;
    uint256 public constant BN254_SCALAR_FIELD =
        21888242871839275222246405745257275088548364400416034343698204186575808495617;

    /**
     * @notice  Performs scalar multiplication in G_1.
     * @param   p  G_1 point to multiply
     * @param   s  Scalar to multiply by
     * @return  r  G_1 point p multiplied by scalar s
     */
    function mulScalar(uint256[2] memory p, uint256 s) internal view returns (uint256[2] memory r) {
        uint256[3] memory input;
        input[0] = p[0];
        input[1] = p[1];
        input[2] = s;
        bool success;
        assembly {
            success := staticcall(sub(gas(), 2000), 7, input, 0x60, r, 0x40)
            switch success
            case 0 { invalid() }
        }
        require(success, "bn254: scalar mul failed");
    }

    /**
     * @notice  Negates a point in G_1.
     * @param   p  G_1 point to negate
     * @return  uint256[2]  G_1 point -p
     */
    function negate(uint256[2] memory p) internal pure returns (uint256[2] memory) {
        if (p[0] == 0 && p[1] == 0) {
            return p;
        }
        return [p[0], BN254_PRIME_FIELD - (p[1] % BN254_PRIME_FIELD)];
    }

    /**
     * @notice  Adds two points in G_1.
     * @param   p1  G_1 point 1
     * @param   p2  G_1 point 2
     * @return  r  G_1 point p1 + p2
     */
    function add(uint256[2] memory p1, uint256[2] memory p2) internal view returns (uint256[2] memory r) {
        bool success;
        uint256[4] memory input = [p1[0], p1[1], p2[0], p2[1]];
        assembly {
            success := staticcall(sub(gas(), 2000), 6, input, 0x80, r, 0x40)
            switch success
            case 0 { invalid() }
        }

        require(success, "bn254: point add failed");
    }

    /**
     * @notice  Computes the pairing check e(p1, p2) * e(p3, p4) == 1
     * @dev     Note that G_2 points a*i + b are encoded as two elements of F_p, (a, b)
     * @param   a_1  G_1 point 1
     * @param   a_2  G_2 point 1
     * @param   b_1  G_1 point 2
     * @param   b_2  G_2 point 2
     * @return  result  true if pairing check is successful
     */
    function pairing(uint256[2] memory a_1, uint256[2][2] memory a_2, uint256[2] memory b_1, uint256[2][2] memory b_2)
        internal
        view
        returns (bool result)
    {
        uint256[12] memory input = [
            a_1[0],
            a_1[1],
            a_2[0][1], // imaginary part first
            a_2[0][0],
            a_2[1][1], // imaginary part first
            a_2[1][0],
            b_1[0],
            b_1[1],
            b_2[0][1], // imaginary part first
            b_2[0][0],
            b_2[1][1], // imaginary part first
            b_2[1][0]
        ];

        uint256[1] memory out;
        bool success;

        assembly {
            success := staticcall(sub(gas(), 2000), 8, input, 0x180, out, 0x20)
            switch success
            case 0 { invalid() }
        }

        require(success, "bn254: pairing failed");

        return out[0] == 1;
    }

    uint256[2] G_1 = [
            21864812957333891501075840188697798411023191078446372461509374117462992292790,
            9368316199604973179823856510100943367762677887892112087253599029566821723927
    ];
    uint256[2][2] G_2 = [
        [
            14095748183821350335948641140115361952326534569022300039515171642778326178024,
            2527950901748606981569133666370539322135901318166798535678295472239735557998
        ],
        [
            5808900702279719966810330861093941880254544320000957918098364052593462682755,
            20816754284144572031417569145977748958219792869726678605819386406497625960964
        ]
    ];
    uint256[2][2] VK = [
        [
            10982632936180737033848000786456651566147524781637756601884094116735622163162,
            4939079467300168475894849271343435780968393372148392720403208710776608081710
        ],
        [
            9172503782664792994257018966511994357831551730375455317739041792202761436191,
            6776112393494196367756403679934688005447432241771368392795298047267808145310
        ]
    ];

    

    /**
     * @notice  Verifies a single point evaluation proof. Function name follows `ark-poly`.
     * @dev     To avoid ops in G_2, we slightly tweak how the verification is done.
     * @param   c  G_1 point commitment to polynomial.
     * @param   pi G_1 point proof.
     * @param   x  Value to prove evaluation of polynomial at.
     * @param   y  Evaluation poly(x).
     * @return  result Indicates if KZG proof is correct.
     */
    function check(uint256[2] calldata c, uint256[2] calldata pi, uint256 x, uint256 y)
        public
        view
        returns (bool result)
    {
        //
        // we want to:
        //      1. avoid gas intensive ops in G2
        //      2. format the pairing check in line with what the evm opcode expects.
        //
        // we can do this by tweaking the KZG check to be:
        //
        //          e(pi, vk - x * g2) = e(c - y * g1, g2) [initial check]
        //          e(pi, vk - x * g2) * e(c - y * g1, g2)^{-1} = 1
        //          e(pi, vk - x * g2) * e(-c + y * g1, g2) = 1 [bilinearity of pairing for all subsequent steps]
        //          e(pi, vk) * e(pi, -x * g2) * e(-c + y * g1, g2) = 1
        //          e(pi, vk) * e(-x * pi, g2) * e(-c + y * g1, g2) = 1
        //          e(pi, vk) * e(x * -pi - c + y * g1, g2) = 1 [done]
        //                        |_   rhs_pairing  _|
        //
        uint256[2] memory rhs_pairing =
            add(mulScalar(negate(pi), x), add(negate(c), mulScalar(G_1, y)));
        return pairing(pi, VK, rhs_pairing, G_2);
    }

    function evalPolyAt(uint256[] memory _coefficients, uint256 _index) public pure returns (uint256) {
        uint256 m = BN254_SCALAR_FIELD;
        uint256 result = 0;
        uint256 powerOfX = 1;

        for (uint256 i = 0; i < _coefficients.length; i++) {
            uint256 coeff = _coefficients[i];
            assembly {
                result := addmod(result, mulmod(powerOfX, coeff, m), m)
                powerOfX := mulmod(powerOfX, _index, m)
            }
        }
        return result;
    }

    
}

/* =============================== */
/* Groth16 verifier methods */
/*
    Copyright 2021 0KIMS association.

    * `solidity-verifiers` added comment
        This file is a template built out of [snarkJS](https://github.com/iden3/snarkjs) groth16 verifier.
        See the original ejs template [here](https://github.com/iden3/snarkjs/blob/master/templates/verifier_groth16.sol.ejs)
    *

    snarkJS is a free software: you can redistribute it and/or modify it
    under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    snarkJS is distributed in the hope that it will be useful, but WITHOUT
    ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
    or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public
    License for more details.

    You should have received a copy of the GNU General Public License
    along with snarkJS. If not, see <https://www.gnu.org/licenses/>.
*/

contract Groth16Verifier {
    // Scalar field size
    uint256 constant r    = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
    // Base field size
    uint256 constant q   = 21888242871839275222246405745257275088696311157297823662689037894645226208583;

    // Verification Key data
    uint256 constant alphax  = 19172703614149247235221465413498416034291425280940869224914281639894130876688;
    uint256 constant alphay  = 15403902174630763677970408218348281485333995728556714115733720624483805586022;
    uint256 constant betax1  = 11391067063640322217462428036750051241579886470266755431487833056814659236969;
    uint256 constant betax2  = 20185234971429332844578836224923377133412988637637356327245313219447584811925;
    uint256 constant betay1  = 18122343846247846364211399966478584909628410142222852839791265597447593650081;
    uint256 constant betay2  = 1507193997820752398813189664596300469406923516367907892480313173188939263355;
    uint256 constant gammax1 = 2246610113634067979561478645502238619979845383152423304708735820987277947824;
    uint256 constant gammax2 = 5320725119834964466273290037433356542915032184981836634301881362872259173098;
    uint256 constant gammay1 = 5667634611836140724138285499805969547921483913492126105343576066885591743901;
    uint256 constant gammay2 = 1857622753619891297349483376362272312201708021164494071184637164784405368966;
    uint256 constant deltax1 = 14948477885816052150405537028203287584259844545909401674441903042376945958145;
    uint256 constant deltax2 = 12801151109673847364753140103131107407670272062435033004384451080664844699459;
    uint256 constant deltay1 = 1913484958502522350089368667498504237105875542848654816363956472175114790583;
    uint256 constant deltay2 = 1733949466794535363717617927239790473654093319476928772264852407023284603636;

    
    uint256 constant IC0x = 7130432230425587945834707743292027594811345689146736095074086465785905792566;
    uint256 constant IC0y = 20123453707156156665052834727985935416952275726462991357041317065901653232353;
    
    uint256 constant IC1x = 4745567577764054759426666685664623978357773806870647033789602566401504895130;
    uint256 constant IC1y = 4517931959454221557600491140309347345262682571870002508786533700137538702590;
    
    uint256 constant IC2x = 316451292010318556642107690726959971924579364454174549069810023434919889766;
    uint256 constant IC2y = 382107745512048162135681325176629205024393518340373177212190862817818607275;
    
    uint256 constant IC3x = 6345761678300348893085123499656279271339263598016622748723123024676465832371;
    uint256 constant IC3y = 17171353957030747679359747689649332136333808226829357657630825830622334882433;
    
    uint256 constant IC4x = 11411020537819180070208350291281458977881657978670413200478789219837520429425;
    uint256 constant IC4y = 17257174176989472950427965594161713711665828438401650421185390096420527292228;
    
    uint256 constant IC5x = 3609465148484286837094696064464925979173508160279361440587823586446333374720;
    uint256 constant IC5y = 8768376742594825523809869004732556092947545130432091089458183724686886435578;
    
    uint256 constant IC6x = 4471201817470290178884716244375349564636500518653102369986082373959901645741;
    uint256 constant IC6y = 20886880233248066188030381015824475911437253974943650552458777116388691450756;
    
    uint256 constant IC7x = 12360924634757472776212260700878618856145551658942540059166241464230449187726;
    uint256 constant IC7y = 15452935307249730842784546065198303571584990049019501425193722414697480341270;
    
    uint256 constant IC8x = 10253015401643243179224442640800433413303075147674728929215060074938578743908;
    uint256 constant IC8y = 3188690847481859207151191392723125835532365655118464554090335091013568658409;
    
    uint256 constant IC9x = 19015712837598000047429203398810129966654068047380617136229191838049501894106;
    uint256 constant IC9y = 1439891234016749024463067694864926390645016323675281181592663316582529129174;
    
    uint256 constant IC10x = 11724905446102104536364721181775557429146540456712448109157765533385596685338;
    uint256 constant IC10y = 10144175721144621571791006333204144248912949657389947117645278069514867651891;
    
    uint256 constant IC11x = 2852625557667422383566691174920437529642736462818497830166856523185542617207;
    uint256 constant IC11y = 13334304118328647267697597611651775985661025470105954891970023068539604018405;
    
    uint256 constant IC12x = 21475189964197917974579186057615444956734238116120155576277097499130384592787;
    uint256 constant IC12y = 4533712275622449915810972195809542442030956663691270340486430685346747701447;
    
    uint256 constant IC13x = 21810694253006996315485703739575389894390440933601957686800119722662901961067;
    uint256 constant IC13y = 14891291322183095628890775719813991078935999604500385685245183901252935862682;
    
    uint256 constant IC14x = 13659645097230201854362247673525042140827909950217516304590372372360466706360;
    uint256 constant IC14y = 1457250400049746043727019597229418545730845303988384200761803810191555973256;
    
    uint256 constant IC15x = 2124606869219293774014509830251495357166674651336969710292091844701142781199;
    uint256 constant IC15y = 18197185667222099581346297097183866519653767001831096235517285511059847255035;
    
    uint256 constant IC16x = 8361426234823242784737297249401577251653647991375916273630300745989338868085;
    uint256 constant IC16y = 3843268805047457082927443296444363384778761242654496551832672011659386272223;
    
    uint256 constant IC17x = 1053295547517762324963564947579544821571870750814109177872372389249614199;
    uint256 constant IC17y = 11963515964110007241082981653730621176497173606657232678051499261501872349648;
    
    uint256 constant IC18x = 2122804345750218706828747384323479181638656636994854523492617533233828828212;
    uint256 constant IC18y = 20771973695478325902583010892910545748531781401115243938453932998218615307581;
    
    uint256 constant IC19x = 6288761392309048122734684888232673068908684477286187814261128562437962402333;
    uint256 constant IC19y = 44549689037016039636912455545023954026437273351703224079651179124377865940;
    
    uint256 constant IC20x = 21361567119531113709318462492651354920052578058551952957147791101832410943121;
    uint256 constant IC20y = 5303749161403410383884924645256109900186680627199906754409999864222090467818;
    
    uint256 constant IC21x = 10432839271645691028606027851980575083542184105375230269016628495895624262116;
    uint256 constant IC21y = 17518634033334517378183761430666509916416451232290390956792527486646663448071;
    
    uint256 constant IC22x = 2505354591654715438452648778330412245089024750547321368819356675716994569642;
    uint256 constant IC22y = 5529452314547649873627492899780369747833240969983750602861792374567032161581;
    
    uint256 constant IC23x = 20464373575788350200792251190585190493112444730293163449616957711312483706749;
    uint256 constant IC23y = 9702795943995113854550228325144764922461663538947563319486451374482877491704;
    
    uint256 constant IC24x = 404349986970855604618381282666190283499726475970665061509843733870344809657;
    uint256 constant IC24y = 9624358057926936676395676124120513263394465188592896494992050942349302975840;
    
    uint256 constant IC25x = 7856796942311889649151654071388895988948870570512316177564151822652894123927;
    uint256 constant IC25y = 20288468498144069393794401119755645151060613583523266178182454359080796034474;
    
    uint256 constant IC26x = 14052674662685380537619193657734768416566687958382569007514259274999739642279;
    uint256 constant IC26y = 10058003330138736010756903508571358467626932469287200766912125266414152888198;
    
    uint256 constant IC27x = 6510645440412414179470821181055954066731752512579752315823743488266103378825;
    uint256 constant IC27y = 67785865200270720380234850896356320048212598863236872464010637169168410614;
    
    uint256 constant IC28x = 17928007719064439839220876775337393066952605698367818593272695290222671285583;
    uint256 constant IC28y = 14947737028226541296471608013460375099062591828256772715559439750961835094538;
    
    uint256 constant IC29x = 10393414114666788789075283010584438487807016919643319959266209004709268725327;
    uint256 constant IC29y = 20738708084033100346818950527437122356463197589362012624774297320672700892804;
    
    uint256 constant IC30x = 14100678899370319062075028676042064422096238803588638956923456340567227724613;
    uint256 constant IC30y = 20886920726942655696128990797212479001659645490671566028784486568187342056690;
    
    uint256 constant IC31x = 3807874721834476060968447447434957485817939610985879155566810209035404372222;
    uint256 constant IC31y = 13716584525920382358710510799490754371135685735566981844227736098601127961917;
    
    uint256 constant IC32x = 1713264963554627940412236156533535581475847384155732741993368086880634434543;
    uint256 constant IC32y = 215451677421635565754213804253797303268788327418937738396790026124865851012;
    
    uint256 constant IC33x = 572151353114266874373184061416367425873327881824947056333438455013001964484;
    uint256 constant IC33y = 8359820577908054109640178782569191779651568972222652328244699204102286819414;
    
    uint256 constant IC34x = 14774955067216948640306142732304460739167164456859076736625215663813759995519;
    uint256 constant IC34y = 20121003115777397110937988587519687180891402195206780382695581037947585205365;
    
    uint256 constant IC35x = 9055512564532330120829689526629689732718701880636798787038664630858466243043;
    uint256 constant IC35y = 7811382791883538271834074763150041568997635631592975398510112862677252788851;
    
    uint256 constant IC36x = 19538779290394093772736432837387238151156624347677091436608014502053603067435;
    uint256 constant IC36y = 174576302400053486210625523821712662528865304180059409195532544023623894594;
    
    uint256 constant IC37x = 7509913961715432895634448055657255046565228713756064457264047448722132497741;
    uint256 constant IC37y = 14212718877471699246762172447228839387400533060736938873513849837873262561391;
    
    uint256 constant IC38x = 6906812732921094430619865592666270888020373105198355509451363401355459786464;
    uint256 constant IC38y = 11335140371462204339490451806537126986289931753931476567710641668004370114249;
    
    uint256 constant IC39x = 11349400633602585208557256181891747068011616062846742093178473245908145987703;
    uint256 constant IC39y = 20095689452827980618766214789560916328854111585776346054701609683229839501856;
    
    uint256 constant IC40x = 21683621082795291719841261114214445227004151864590762702910810912580723988077;
    uint256 constant IC40y = 4700836397989741760655617356819084776656580509672360037582202293662889074516;
    
    uint256 constant IC41x = 13579183466748791305722549596814891542131980299482774996152023560821345789755;
    uint256 constant IC41y = 15514124190921881414333503375733352159673709197997678269167430089968884387792;
    
    uint256 constant IC42x = 10034118333296167060832169933150307925607321188070966593360729342312870120973;
    uint256 constant IC42y = 14709528629684251015799301507184908798487388449979530429206827236584603597800;
    
    uint256 constant IC43x = 21726135963179267578555084097137156358071085818961124596218301241200554331900;
    uint256 constant IC43y = 13427257690023569390322463654298344470638401741041552659235850128074681091905;
    
    uint256 constant IC44x = 2440101081243380907548018161436333296214091906478248179212102618102880394618;
    uint256 constant IC44y = 7559947444684384441195723479314186816479066564219268190509538044816523632365;
    
    
    // Memory data
    uint16 constant pVk = 0;
    uint16 constant pPairing = 128;

    uint16 constant pLastMem = 896;

    function verifyProof(uint[2] calldata _pA, uint[2][2] calldata _pB, uint[2] calldata _pC, uint[44] calldata _pubSignals) public view returns (bool) {
        assembly {
            function checkField(v) {
                if iszero(lt(v, r)) {
                    mstore(0, 0)
                    return(0, 0x20)
                }
            }
            
            // G1 function to multiply a G1 value(x,y) to value in an address
            function g1_mulAccC(pR, x, y, s) {
                let success
                let mIn := mload(0x40)
                mstore(mIn, x)
                mstore(add(mIn, 32), y)
                mstore(add(mIn, 64), s)

                success := staticcall(sub(gas(), 2000), 7, mIn, 96, mIn, 64)

                if iszero(success) {
                    mstore(0, 0)
                    return(0, 0x20)
                }

                mstore(add(mIn, 64), mload(pR))
                mstore(add(mIn, 96), mload(add(pR, 32)))

                success := staticcall(sub(gas(), 2000), 6, mIn, 128, pR, 64)

                if iszero(success) {
                    mstore(0, 0)
                    return(0, 0x20)
                }
            }

            function checkPairing(pA, pB, pC, pubSignals, pMem) -> isOk {
                let _pPairing := add(pMem, pPairing)
                let _pVk := add(pMem, pVk)

                mstore(_pVk, IC0x)
                mstore(add(_pVk, 32), IC0y)

                // Compute the linear combination vk_x
                
                
                g1_mulAccC(_pVk, IC1x, IC1y, calldataload(add(pubSignals, 0)))
                g1_mulAccC(_pVk, IC2x, IC2y, calldataload(add(pubSignals, 32)))
                g1_mulAccC(_pVk, IC3x, IC3y, calldataload(add(pubSignals, 64)))
                g1_mulAccC(_pVk, IC4x, IC4y, calldataload(add(pubSignals, 96)))
                g1_mulAccC(_pVk, IC5x, IC5y, calldataload(add(pubSignals, 128)))
                g1_mulAccC(_pVk, IC6x, IC6y, calldataload(add(pubSignals, 160)))
                g1_mulAccC(_pVk, IC7x, IC7y, calldataload(add(pubSignals, 192)))
                g1_mulAccC(_pVk, IC8x, IC8y, calldataload(add(pubSignals, 224)))
                g1_mulAccC(_pVk, IC9x, IC9y, calldataload(add(pubSignals, 256)))
                g1_mulAccC(_pVk, IC10x, IC10y, calldataload(add(pubSignals, 288)))
                g1_mulAccC(_pVk, IC11x, IC11y, calldataload(add(pubSignals, 320)))
                g1_mulAccC(_pVk, IC12x, IC12y, calldataload(add(pubSignals, 352)))
                g1_mulAccC(_pVk, IC13x, IC13y, calldataload(add(pubSignals, 384)))
                g1_mulAccC(_pVk, IC14x, IC14y, calldataload(add(pubSignals, 416)))
                g1_mulAccC(_pVk, IC15x, IC15y, calldataload(add(pubSignals, 448)))
                g1_mulAccC(_pVk, IC16x, IC16y, calldataload(add(pubSignals, 480)))
                g1_mulAccC(_pVk, IC17x, IC17y, calldataload(add(pubSignals, 512)))
                g1_mulAccC(_pVk, IC18x, IC18y, calldataload(add(pubSignals, 544)))
                g1_mulAccC(_pVk, IC19x, IC19y, calldataload(add(pubSignals, 576)))
                g1_mulAccC(_pVk, IC20x, IC20y, calldataload(add(pubSignals, 608)))
                g1_mulAccC(_pVk, IC21x, IC21y, calldataload(add(pubSignals, 640)))
                g1_mulAccC(_pVk, IC22x, IC22y, calldataload(add(pubSignals, 672)))
                g1_mulAccC(_pVk, IC23x, IC23y, calldataload(add(pubSignals, 704)))
                g1_mulAccC(_pVk, IC24x, IC24y, calldataload(add(pubSignals, 736)))
                g1_mulAccC(_pVk, IC25x, IC25y, calldataload(add(pubSignals, 768)))
                g1_mulAccC(_pVk, IC26x, IC26y, calldataload(add(pubSignals, 800)))
                g1_mulAccC(_pVk, IC27x, IC27y, calldataload(add(pubSignals, 832)))
                g1_mulAccC(_pVk, IC28x, IC28y, calldataload(add(pubSignals, 864)))
                g1_mulAccC(_pVk, IC29x, IC29y, calldataload(add(pubSignals, 896)))
                g1_mulAccC(_pVk, IC30x, IC30y, calldataload(add(pubSignals, 928)))
                g1_mulAccC(_pVk, IC31x, IC31y, calldataload(add(pubSignals, 960)))
                g1_mulAccC(_pVk, IC32x, IC32y, calldataload(add(pubSignals, 992)))
                g1_mulAccC(_pVk, IC33x, IC33y, calldataload(add(pubSignals, 1024)))
                g1_mulAccC(_pVk, IC34x, IC34y, calldataload(add(pubSignals, 1056)))
                g1_mulAccC(_pVk, IC35x, IC35y, calldataload(add(pubSignals, 1088)))
                g1_mulAccC(_pVk, IC36x, IC36y, calldataload(add(pubSignals, 1120)))
                g1_mulAccC(_pVk, IC37x, IC37y, calldataload(add(pubSignals, 1152)))
                g1_mulAccC(_pVk, IC38x, IC38y, calldataload(add(pubSignals, 1184)))
                g1_mulAccC(_pVk, IC39x, IC39y, calldataload(add(pubSignals, 1216)))
                g1_mulAccC(_pVk, IC40x, IC40y, calldataload(add(pubSignals, 1248)))
                g1_mulAccC(_pVk, IC41x, IC41y, calldataload(add(pubSignals, 1280)))
                g1_mulAccC(_pVk, IC42x, IC42y, calldataload(add(pubSignals, 1312)))
                g1_mulAccC(_pVk, IC43x, IC43y, calldataload(add(pubSignals, 1344)))
                g1_mulAccC(_pVk, IC44x, IC44y, calldataload(add(pubSignals, 1376)))

                // -A
                mstore(_pPairing, calldataload(pA))
                mstore(add(_pPairing, 32), mod(sub(q, calldataload(add(pA, 32))), q))

                // B
                mstore(add(_pPairing, 64), calldataload(pB))
                mstore(add(_pPairing, 96), calldataload(add(pB, 32)))
                mstore(add(_pPairing, 128), calldataload(add(pB, 64)))
                mstore(add(_pPairing, 160), calldataload(add(pB, 96)))

                // alpha1
                mstore(add(_pPairing, 192), alphax)
                mstore(add(_pPairing, 224), alphay)

                // beta2
                mstore(add(_pPairing, 256), betax1)
                mstore(add(_pPairing, 288), betax2)
                mstore(add(_pPairing, 320), betay1)
                mstore(add(_pPairing, 352), betay2)

                // vk_x
                mstore(add(_pPairing, 384), mload(add(pMem, pVk)))
                mstore(add(_pPairing, 416), mload(add(pMem, add(pVk, 32))))


                // gamma2
                mstore(add(_pPairing, 448), gammax1)
                mstore(add(_pPairing, 480), gammax2)
                mstore(add(_pPairing, 512), gammay1)
                mstore(add(_pPairing, 544), gammay2)

                // C
                mstore(add(_pPairing, 576), calldataload(pC))
                mstore(add(_pPairing, 608), calldataload(add(pC, 32)))

                // delta2
                mstore(add(_pPairing, 640), deltax1)
                mstore(add(_pPairing, 672), deltax2)
                mstore(add(_pPairing, 704), deltay1)
                mstore(add(_pPairing, 736), deltay2)


                let success := staticcall(sub(gas(), 2000), 8, _pPairing, 768, _pPairing, 0x20)

                isOk := and(success, mload(_pPairing))
            }

            let pMem := mload(0x40)
            mstore(0x40, add(pMem, pLastMem))

            // Validate that all evaluations ∈ F
            
            checkField(calldataload(add(_pubSignals, 0)))
            
            checkField(calldataload(add(_pubSignals, 32)))
            
            checkField(calldataload(add(_pubSignals, 64)))
            
            checkField(calldataload(add(_pubSignals, 96)))
            
            checkField(calldataload(add(_pubSignals, 128)))
            
            checkField(calldataload(add(_pubSignals, 160)))
            
            checkField(calldataload(add(_pubSignals, 192)))
            
            checkField(calldataload(add(_pubSignals, 224)))
            
            checkField(calldataload(add(_pubSignals, 256)))
            
            checkField(calldataload(add(_pubSignals, 288)))
            
            checkField(calldataload(add(_pubSignals, 320)))
            
            checkField(calldataload(add(_pubSignals, 352)))
            
            checkField(calldataload(add(_pubSignals, 384)))
            
            checkField(calldataload(add(_pubSignals, 416)))
            
            checkField(calldataload(add(_pubSignals, 448)))
            
            checkField(calldataload(add(_pubSignals, 480)))
            
            checkField(calldataload(add(_pubSignals, 512)))
            
            checkField(calldataload(add(_pubSignals, 544)))
            
            checkField(calldataload(add(_pubSignals, 576)))
            
            checkField(calldataload(add(_pubSignals, 608)))
            
            checkField(calldataload(add(_pubSignals, 640)))
            
            checkField(calldataload(add(_pubSignals, 672)))
            
            checkField(calldataload(add(_pubSignals, 704)))
            
            checkField(calldataload(add(_pubSignals, 736)))
            
            checkField(calldataload(add(_pubSignals, 768)))
            
            checkField(calldataload(add(_pubSignals, 800)))
            
            checkField(calldataload(add(_pubSignals, 832)))
            
            checkField(calldataload(add(_pubSignals, 864)))
            
            checkField(calldataload(add(_pubSignals, 896)))
            
            checkField(calldataload(add(_pubSignals, 928)))
            
            checkField(calldataload(add(_pubSignals, 960)))
            
            checkField(calldataload(add(_pubSignals, 992)))
            
            checkField(calldataload(add(_pubSignals, 1024)))
            
            checkField(calldataload(add(_pubSignals, 1056)))
            
            checkField(calldataload(add(_pubSignals, 1088)))
            
            checkField(calldataload(add(_pubSignals, 1120)))
            
            checkField(calldataload(add(_pubSignals, 1152)))
            
            checkField(calldataload(add(_pubSignals, 1184)))
            
            checkField(calldataload(add(_pubSignals, 1216)))
            
            checkField(calldataload(add(_pubSignals, 1248)))
            
            checkField(calldataload(add(_pubSignals, 1280)))
            
            checkField(calldataload(add(_pubSignals, 1312)))
            
            checkField(calldataload(add(_pubSignals, 1344)))
            
            checkField(calldataload(add(_pubSignals, 1376)))
            
            checkField(calldataload(add(_pubSignals, 1408)))
            

            // Validate all evaluations
            let isValid := checkPairing(_pA, _pB, _pC, _pubSignals, pMem)

            mstore(0, isValid)
            
            return(0, 0x20)
        }
    }
}


/* =============================== */
/* Nova+CycleFold Decider verifier */
/**
 * @notice  Computes the decomposition of a `uint256` into num_limbs limbs of bits_per_limb bits each.
 * @dev     Compatible with sonobe::folding-schemes::folding::circuits::nonnative::nonnative_field_to_field_elements.
 */
library LimbsDecomposition {
    function decompose(uint256 x) internal pure returns (uint256[5] memory) {
        uint256[5] memory limbs;
        for (uint8 i = 0; i < 5; i++) {
            limbs[i] = (x >> (55 * i)) & ((1 << 55) - 1);
        }
        return limbs;
    }
}

/**
 * @author  PSE & 0xPARC
 * @title   NovaDecider contract, for verifying Nova IVC SNARK proofs.
 * @dev     This is an askama template which, when templated, features a Groth16 and KZG10 verifiers from which this contract inherits.
 */
contract NovaDecider is Groth16Verifier, KZG10Verifier {
    /**
     * @notice  Computes the linear combination of a and b with r as the coefficient.
     * @dev     All ops are done mod the BN254 scalar field prime
     */
    function rlc(uint256 a, uint256 r, uint256 b) internal pure returns (uint256 result) {
        assembly {
            result := addmod(a, mulmod(r, b, BN254_SCALAR_FIELD), BN254_SCALAR_FIELD)
        }
    }

    /**
     * @notice  Verifies a nova cyclefold proof consisting of two KZG proofs and of a groth16 proof.
     * @dev     The selector of this function is "dynamic", since it depends on `z_len`.
     */
    function verifyNovaProof(
        // inputs are grouped to prevent errors due stack too deep
        uint256[5] calldata i_z0_zi, // [i, z0, zi] where |z0| == |zi|
        uint256[4] calldata U_i_cmW_U_i_cmE, // [U_i_cmW[2], U_i_cmE[2]]
        uint256[3] calldata U_i_u_u_i_u_r, // [U_i_u, u_i_u, r]
        uint256[4] calldata U_i_x_u_i_cmW, // [U_i_x[2], u_i_cmW[2]]
        uint256[4] calldata u_i_x_cmT, // [u_i_x[2], cmT[2]]
        uint256[2] calldata pA, // groth16 
        uint256[2][2] calldata pB, // groth16
        uint256[2] calldata pC, // groth16
        uint256[4] calldata challenge_W_challenge_E_kzg_evals, // [challenge_W, challenge_E, eval_W, eval_E]
        uint256[2][2] calldata kzg_proof // [proof_W, proof_E]
    ) public view returns (bool) {

        require(i_z0_zi[0] >= 2, "Folding: the number of folded steps should be at least 2");

        // from gamma_abc_len, we subtract 1. 
        uint256[44] memory public_inputs; 

        public_inputs[0] = 596544891790520164842844577374031722705062083950981751269201852094364676743;
        public_inputs[1] = i_z0_zi[0];

        for (uint i = 0; i < 4; i++) {
            public_inputs[2 + i] = i_z0_zi[1 + i];
        }

        {
            // U_i.u + r * u_i.u
            uint256 u = rlc(U_i_u_u_i_u_r[0], U_i_u_u_i_u_r[2], U_i_u_u_i_u_r[1]);
            // U_i.x + r * u_i.x
            uint256 x0 = rlc(U_i_x_u_i_cmW[0], U_i_u_u_i_u_r[2], u_i_x_cmT[0]);
            uint256 x1 = rlc(U_i_x_u_i_cmW[1], U_i_u_u_i_u_r[2], u_i_x_cmT[1]);

            public_inputs[6] = u;
            public_inputs[7] = x0;
            public_inputs[8] = x1;
        }

        {
            // U_i.cmE + r * u_i.cmT
            uint256[2] memory mulScalarPoint = super.mulScalar([u_i_x_cmT[2], u_i_x_cmT[3]], U_i_u_u_i_u_r[2]);
            uint256[2] memory cmE = super.add([U_i_cmW_U_i_cmE[2], U_i_cmW_U_i_cmE[3]], mulScalarPoint);

            {
                uint256[5] memory cmE_x_limbs = LimbsDecomposition.decompose(cmE[0]);
                uint256[5] memory cmE_y_limbs = LimbsDecomposition.decompose(cmE[1]);
            
                for (uint8 k = 0; k < 5; k++) {
                    public_inputs[9 + k] = cmE_x_limbs[k];
                    public_inputs[14 + k] = cmE_y_limbs[k];
                }
            }

            require(this.check(cmE, kzg_proof[1], challenge_W_challenge_E_kzg_evals[1], challenge_W_challenge_E_kzg_evals[3]), "KZG: verifying proof for challenge E failed");
        }

        {
            // U_i.cmW + r * u_i.cmW
            uint256[2] memory mulScalarPoint = super.mulScalar([U_i_x_u_i_cmW[2], U_i_x_u_i_cmW[3]], U_i_u_u_i_u_r[2]);
            uint256[2] memory cmW = super.add([U_i_cmW_U_i_cmE[0], U_i_cmW_U_i_cmE[1]], mulScalarPoint);
        
            {
                uint256[5] memory cmW_x_limbs = LimbsDecomposition.decompose(cmW[0]);
                uint256[5] memory cmW_y_limbs = LimbsDecomposition.decompose(cmW[1]);
        
                for (uint8 k = 0; k < 5; k++) {
                    public_inputs[19 + k] = cmW_x_limbs[k];
                    public_inputs[24 + k] = cmW_y_limbs[k];
                }
            }
        
            require(this.check(cmW, kzg_proof[0], challenge_W_challenge_E_kzg_evals[0], challenge_W_challenge_E_kzg_evals[2]), "KZG: verifying proof for challenge W failed");
        }

        {
            // add challenges
            public_inputs[29] = challenge_W_challenge_E_kzg_evals[0];
            public_inputs[30] = challenge_W_challenge_E_kzg_evals[1];
            public_inputs[31] = challenge_W_challenge_E_kzg_evals[2];
            public_inputs[32] = challenge_W_challenge_E_kzg_evals[3];
        
            uint256[5] memory cmT_x_limbs;
            uint256[5] memory cmT_y_limbs;
        
            cmT_x_limbs = LimbsDecomposition.decompose(u_i_x_cmT[2]);
            cmT_y_limbs = LimbsDecomposition.decompose(u_i_x_cmT[3]);
        
            for (uint8 k = 0; k < 5; k++) {
                public_inputs[29 + 4 + k] = cmT_x_limbs[k]; 
                public_inputs[34 + 4 + k] = cmT_y_limbs[k];
            }
        
            // last element of the groth16 proof's public inputs is `r`
            public_inputs[43] = U_i_u_u_i_u_r[2];
            
            bool success_g16 = this.verifyProof(pA, pB, pC, public_inputs);
            require(success_g16 == true, "Groth16: verifying proof failed");
        }

        return(true);
    }
}