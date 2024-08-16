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
            4134757118588709835094473634926298828694227620492408920540802235305084983176,
            11903636433721772132905736242876413821659280057394951418801750093863795398776
    ];
    uint256[2][2] G_2 = [
        [
            13526563947709693911173850334896042792833986783217743617407012739819184184108,
            5662171823470227855332963847658169984557676586820739061043529184290658971248
        ],
        [
            8749300093194400903602049446057498671234304994012725904108928974719924254660,
            11191342874380475002174258668844386810164847136359962452173634731803319065651
        ]
    ];
    uint256[2][2] VK = [
        [
            4630319215426535929458231852488192656429287438287969151846581851542565317693,
            12340166115894326174325897823428069318408608466346155163132515340208889404245
        ],
        [
            11504595019740557276497740616697946405489217116080258192631612814986980189929,
            7160495714461835178753729883906437568755534123973034906945511750873638393365
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
    uint256 constant alphax  = 21836168354830437203996108542970868253721584347701865078920332179323453364461;
    uint256 constant alphay  = 13285584027555637550648751035687984529194359995820750516274748927213473019975;
    uint256 constant betax1  = 21098157666929922619020463708933170291761778001776518363402744494846968384337;
    uint256 constant betax2  = 10796178526112603504264350910474365100087791119243653522506728778183482672111;
    uint256 constant betay1  = 13500470242068588659875698404180157289458319048373340410965885616075028034893;
    uint256 constant betay2  = 13675503462667308950068617286276731551583147257033769364673040236245131900704;
    uint256 constant gammax1 = 20852356833405607655897988527800115095708728348278308394995378279067341928772;
    uint256 constant gammax2 = 18747086044694432927235050965433103637073947205536368690735935187235074124604;
    uint256 constant gammay1 = 11354449197753420544028797493565847897904472220764194431119806303649889164397;
    uint256 constant gammay2 = 18647022856190274335942237513402334676406136009205043119589450595210039634113;
    uint256 constant deltax1 = 19724892553202274783928543057231491839845352047397828758190745988068019362812;
    uint256 constant deltax2 = 12851001931231641765112891053165232725775370056119750093066704302638834521559;
    uint256 constant deltay1 = 17787822891637996460698620533107472349330290910327906995076029773267927682063;
    uint256 constant deltay2 = 9292586453238026395966694832897705758996059241329378838863825681057214468809;

    
    uint256 constant IC0x = 2760284279987213219505759921075856211466205718123188953009564646712988532543;
    uint256 constant IC0y = 17224519515691143874449737015547007393321850034070977601191238832345269611655;
    
    uint256 constant IC1x = 7154803113373644086694303410935952009873243673433516528680163324164133353170;
    uint256 constant IC1y = 10366861854369899298523651873360716067755362765098986517952990831644869069576;
    
    uint256 constant IC2x = 6610794414512506222895483026303813374890645554769651349124831568056895761484;
    uint256 constant IC2y = 13677388393590918240858338097947306187582480864629204049085524664442907096680;
    
    uint256 constant IC3x = 16128723104093795537752791999194002691734142668024494646278162011849934999137;
    uint256 constant IC3y = 6034159994285094896302464450605382826530016398313550977691373009095447853110;
    
    uint256 constant IC4x = 19006730393029112014067002421872948320193209852051652462537316062908934939450;
    uint256 constant IC4y = 9499302367309536342578809230750818634848649258266103728759807876120973756754;
    
    uint256 constant IC5x = 6174986326890525644628012644511166287025857388030774565596930032004090380654;
    uint256 constant IC5y = 4415257266290072188207641791239482440037612302439701252935527093540895941234;
    
    uint256 constant IC6x = 15714317968911146334986552423331854061400624516653255557740776377496381305291;
    uint256 constant IC6y = 4937515544467774114878946400558788873850258545256901508225367756191203489528;
    
    uint256 constant IC7x = 11135426742712896456409973029392485735095528887391324094016323375101485483978;
    uint256 constant IC7y = 3594948733602283848582365998727099790988239482622438692447541586074687666971;
    
    uint256 constant IC8x = 18648346696630814741994510240693586045582505865868517387105743675112915240099;
    uint256 constant IC8y = 14239373395983786993205070045523691804361091780058993278492369954960863341163;
    
    uint256 constant IC9x = 11566534185086989295546906137296194537630714023537275349429891002438911082411;
    uint256 constant IC9y = 20883668364208922111366582888657195218966604125765814252689417511526566638497;
    
    uint256 constant IC10x = 12905579209876026968423220879481905922111203999992084792679861670898941153422;
    uint256 constant IC10y = 7205959968126116339253986219400595491537588246785125086690384216112862498349;
    
    uint256 constant IC11x = 5691051972712569429278471638375187751845009894379318521062083097826053907100;
    uint256 constant IC11y = 15421762825985112865681360849003359092663553686776043264975698328332658630676;
    
    uint256 constant IC12x = 5501842789776114792248923250292468025717930032217356470135344273121604056274;
    uint256 constant IC12y = 11993699698048459009045270950361624507342268975705142013995615281854495664133;
    
    uint256 constant IC13x = 14237436786225714641266622391626675771844535227499638192543480751050971564365;
    uint256 constant IC13y = 11195644739919859375126847642667847753275183876295809188590328651200350945171;
    
    uint256 constant IC14x = 14430242728100504387373625538191807867347110471718804394683754354131602207204;
    uint256 constant IC14y = 16052900626512400236914818818901310261242528141135440617203863922226144643741;
    
    uint256 constant IC15x = 4272366119502654980974432220670654818913293356781098629472998893688256338132;
    uint256 constant IC15y = 9066795434630331966090709350321342033583451074536947860561549158129116661905;
    
    uint256 constant IC16x = 4585291700286666779744520758510271980336288344873304842407790165363689504557;
    uint256 constant IC16y = 3200423378318870581468541481840618916897594790364527051334314690240896671597;
    
    uint256 constant IC17x = 14674513706162345392067287546168295547115375544909299928017823247516146024246;
    uint256 constant IC17y = 18181337787704709149218309939118031348073296469488119776553157774030504580417;
    
    uint256 constant IC18x = 8164457143242564756321106467097117890519226210795787931025099294473542427785;
    uint256 constant IC18y = 15281084700766449462869410625378290492631218480056286055551394165034132554489;
    
    uint256 constant IC19x = 128482188494878852949450398225309466643816302801885510219329746514846182723;
    uint256 constant IC19y = 17288735220636964953911242775053617268529293277010038561156411171546188933410;
    
    uint256 constant IC20x = 20798946404857981768727460659714565995044088434759383498090167654783688848000;
    uint256 constant IC20y = 10979470312870519777088964194679665367297858404294499691402213145605814342459;
    
    uint256 constant IC21x = 7645342887492746386949465039029491784485656032062820633032129980188983804425;
    uint256 constant IC21y = 17637908377374000812404524415805176380154583331361498282024416348457368612590;
    
    uint256 constant IC22x = 8164170812070120147812487901210717448140970157777072287984732579352988554273;
    uint256 constant IC22y = 2810057415022043773398731031626742063399102935225289452634016572241690746179;
    
    uint256 constant IC23x = 6719240108680030379331875260161159566780090691570686485603669469697541951720;
    uint256 constant IC23y = 10691116287058196158971305457557539694675667115264608959486780008194694967701;
    
    uint256 constant IC24x = 11770631880152727308588253394990183988777394303508876674059528721363651784457;
    uint256 constant IC24y = 13000839638038978335062929875133779664740152368791218368321967021292267164703;
    
    uint256 constant IC25x = 12969608616592331321787935271619576739347500992276979386766374859947587511303;
    uint256 constant IC25y = 11152585999002158826203973427801773936279589502594227684826414747825443400707;
    
    uint256 constant IC26x = 10505085951874833486161531916274265455713280605384285373252824364778624838629;
    uint256 constant IC26y = 12834100867712544700041154509017653640876163726481661128080540815206566828994;
    
    uint256 constant IC27x = 3079573609974480771929394523660617764283029507935407091612446317701261650159;
    uint256 constant IC27y = 19723973055066757554057681662826833510548658135993894677869822086800290599279;
    
    uint256 constant IC28x = 11388118426552028682280366849181802708115802626023387497575015819677271698965;
    uint256 constant IC28y = 5326950067041657654014227160370768263815290893508494391156963652554392060157;
    
    uint256 constant IC29x = 11431071424754449581393703949218386890277696078704911313348478177644843297636;
    uint256 constant IC29y = 12949384946592467158546131157774379331467040390315039357064837553032260922536;
    
    uint256 constant IC30x = 20065813874487720682293299249900399680494925295186220291313869167260959903367;
    uint256 constant IC30y = 2707758754892508726757638929594397163959768531042507572437135469579320135736;
    
    uint256 constant IC31x = 17073289773866675583534165490540565062929594342446912975051200645580341251868;
    uint256 constant IC31y = 14920742243019983579131395896044427550911446403387239249741867322190526358389;
    
    uint256 constant IC32x = 10253595803653909617941622047633180784610036305371030264437090083779853491035;
    uint256 constant IC32y = 21101901568344128665978532066539707492027406124787106616972463462424083802365;
    
    uint256 constant IC33x = 17910671311148709845170793259275414334148290637039742282743735942733613297811;
    uint256 constant IC33y = 17608658348075875110488228025598135823588485679251432071588589765085011904689;
    
    uint256 constant IC34x = 2537815249128571215986515544640997305401484551618022258360424904473097797943;
    uint256 constant IC34y = 14686861965560553366869529646496229262780036078370339541694751324563099385361;
    
    uint256 constant IC35x = 18879690264376623882219707062254385415015979868612553557707009716755533011152;
    uint256 constant IC35y = 5408329700125178835540650104653975654607601427219018706179390713356880529791;
    
    uint256 constant IC36x = 9847843003567377349172921661003659718437062952245152182355164011389692139757;
    uint256 constant IC36y = 7267643218898890341117714499129835335536356007542731782517290868167092344022;
    
    uint256 constant IC37x = 12941512297641596675066536152254848404138421519993817624652958301420273141410;
    uint256 constant IC37y = 17440550013881837258756794438575704705060021767302063840850131828212101591158;
    
    uint256 constant IC38x = 490188095563895441919482740224324023632901180350225137085676626689273478840;
    uint256 constant IC38y = 6010352735439050438174676743786249589413809917482500904670000040418172261227;
    
    uint256 constant IC39x = 8217248932116093440782947585094246935176231019966697649857554545985078662041;
    uint256 constant IC39y = 15192224509283652554336065335529436181476726399639300365177412640220746015794;
    
    uint256 constant IC40x = 2306254272510438919217465288467518130453040670718277659608175397097685835842;
    uint256 constant IC40y = 14918173489938676680570667442904238585155614319397055471602935344888502212469;
    
    uint256 constant IC41x = 19188764791396341071021871119279709342291630436732840188348607815568739578551;
    uint256 constant IC41y = 3456210235662689384813619010211862049279645105855965501571445456802579352833;
    
    uint256 constant IC42x = 15452929184374027063104987674431105762921059940730438883069478713105234419638;
    uint256 constant IC42y = 15461550109865638478549470624087228166078935335567862338722504069773431834739;
    
    
    // Memory data
    uint16 constant pVk = 0;
    uint16 constant pPairing = 128;

    uint16 constant pLastMem = 896;

    function verifyProof(uint[2] calldata _pA, uint[2][2] calldata _pB, uint[2] calldata _pC, uint[42] calldata _pubSignals) public view returns (bool) {
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
        uint256[3] calldata i_z0_zi, // [i, z0, zi] where |z0| == |zi|
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
        uint256[42] memory public_inputs; 

        public_inputs[0] = 4897072920956987970211427618956684926634189597662783774235177671241408430275;
        public_inputs[1] = i_z0_zi[0];

        for (uint i = 0; i < 2; i++) {
            public_inputs[2 + i] = i_z0_zi[1 + i];
        }

        {
            // U_i.u + r * u_i.u
            uint256 u = rlc(U_i_u_u_i_u_r[0], U_i_u_u_i_u_r[2], U_i_u_u_i_u_r[1]);
            // U_i.x + r * u_i.x
            uint256 x0 = rlc(U_i_x_u_i_cmW[0], U_i_u_u_i_u_r[2], u_i_x_cmT[0]);
            uint256 x1 = rlc(U_i_x_u_i_cmW[1], U_i_u_u_i_u_r[2], u_i_x_cmT[1]);

            public_inputs[4] = u;
            public_inputs[5] = x0;
            public_inputs[6] = x1;
        }

        {
            // U_i.cmE + r * u_i.cmT
            uint256[2] memory mulScalarPoint = super.mulScalar([u_i_x_cmT[2], u_i_x_cmT[3]], U_i_u_u_i_u_r[2]);
            uint256[2] memory cmE = super.add([U_i_cmW_U_i_cmE[2], U_i_cmW_U_i_cmE[3]], mulScalarPoint);

            {
                uint256[5] memory cmE_x_limbs = LimbsDecomposition.decompose(cmE[0]);
                uint256[5] memory cmE_y_limbs = LimbsDecomposition.decompose(cmE[1]);
            
                for (uint8 k = 0; k < 5; k++) {
                    public_inputs[7 + k] = cmE_x_limbs[k];
                    public_inputs[12 + k] = cmE_y_limbs[k];
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
                    public_inputs[17 + k] = cmW_x_limbs[k];
                    public_inputs[22 + k] = cmW_y_limbs[k];
                }
            }
        
            require(this.check(cmW, kzg_proof[0], challenge_W_challenge_E_kzg_evals[0], challenge_W_challenge_E_kzg_evals[2]), "KZG: verifying proof for challenge W failed");
        }

        {
            // add challenges
            public_inputs[27] = challenge_W_challenge_E_kzg_evals[0];
            public_inputs[28] = challenge_W_challenge_E_kzg_evals[1];
            public_inputs[29] = challenge_W_challenge_E_kzg_evals[2];
            public_inputs[30] = challenge_W_challenge_E_kzg_evals[3];
        
            uint256[5] memory cmT_x_limbs;
            uint256[5] memory cmT_y_limbs;
        
            cmT_x_limbs = LimbsDecomposition.decompose(u_i_x_cmT[2]);
            cmT_y_limbs = LimbsDecomposition.decompose(u_i_x_cmT[3]);
        
            for (uint8 k = 0; k < 5; k++) {
                public_inputs[27 + 4 + k] = cmT_x_limbs[k]; 
                public_inputs[32 + 4 + k] = cmT_y_limbs[k];
            }
        
            // last element of the groth16 proof's public inputs is `r`
            public_inputs[41] = U_i_u_u_i_u_r[2];
            
            bool success_g16 = this.verifyProof(pA, pB, pC, public_inputs);
            require(success_g16 == true, "Groth16: verifying proof failed");
        }

        return(true);
    }
}