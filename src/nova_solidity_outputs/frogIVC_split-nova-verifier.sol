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
            19102815345632523781896348341458917381684786381728491641254682846001279329898,
            13451266616691543380674910399213812465400160681414870618759879880164626928770
    ];
    uint256[2][2] G_2 = [
        [
            21050417171652896756697231785353448207541277918399279531444385302242303510076,
            217143643782578348726151680016400723968884217505547521106696637398884994429
        ],
        [
            34302904510653327697226891629638762064245529180907533028207511009538218782,
            8828141809723396587096502363046137028402924188935555640169837648083204785287
        ]
    ];
    uint256[2][2] VK = [
        [
            19988448128881070018974468599225338168067044269641153902282001368180323337990,
            9834604130832881335583700961071099381023040678533147532816521548513585102009
        ],
        [
            9746333066623173616604596158136739333338468794771955501995521688859094895087,
            6233829725421832699920562363905908931126258352381271355844554520048031091593
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
    uint256 constant alphax  = 17533364627681552087120383337293438105681287362390869423184136705503139934243;
    uint256 constant alphay  = 17102719962985994041810625090480061828878263234765762387696865582789558097962;
    uint256 constant betax1  = 14404214443590029315943674833002877392862953622239256010388384108317928476411;
    uint256 constant betax2  = 10405667727648510449095474095053184878462948095643035155676690064973222058925;
    uint256 constant betay1  = 9298030464171992759760537295421691874336757781920524309797097590697401292055;
    uint256 constant betay2  = 21456289017306642103642664494197556606120691142127815456119111051629129122118;
    uint256 constant gammax1 = 19609969720832637548356455485520551992210099606259274528355553656941125058542;
    uint256 constant gammax2 = 13034456406992351059360537238599876761738623258913294928144750474658205497894;
    uint256 constant gammay1 = 14128510785530266008451810313459148994280286996834928777297276794791874441924;
    uint256 constant gammay2 = 18128013328579324065232653203832683888346487815577160588401110636725397894433;
    uint256 constant deltax1 = 3897108671740729788204489317651106142140034858313567882493526359806722192077;
    uint256 constant deltax2 = 1639731151892615416680837090978782142093291373511558162375254822170871184879;
    uint256 constant deltay1 = 3998548696632939568271999416162625297856675855108251183700544388114771652334;
    uint256 constant deltay2 = 10901236603443113089753622218315209221604795476567092785101009730584031244796;

    
    uint256 constant IC0x = 12141678995329789039763810355648675395115479952897846086665098146635583465346;
    uint256 constant IC0y = 3106620951438260436660469218866746029083537183893096216717271269299786998793;
    
    uint256 constant IC1x = 5738842019205679519064868087976685185044051113945047209879298100576852123929;
    uint256 constant IC1y = 20655698725536369436392978374394561540799397201065042695943311008356468698635;
    
    uint256 constant IC2x = 9093545309825682246493727231776688692891259987534470636078862759227872909499;
    uint256 constant IC2y = 10914294993933725081696983162381191460483430481318162732135454447824428816875;
    
    uint256 constant IC3x = 4889633422349908159386444800231612924699805265096516627486549381804000060967;
    uint256 constant IC3y = 14360786455209257755983286853586474405133112694347126106080402877470990639744;
    
    uint256 constant IC4x = 4539847953902215149658306469728118032051108067476994008033439538259145731828;
    uint256 constant IC4y = 15928644696985842258817223149200186529759366992406631418931985957513235954217;
    
    uint256 constant IC5x = 3081393219474696283126310284133379758007524886459296996033529809377913290088;
    uint256 constant IC5y = 16161900089033091209909259770348721797204652003081433680866946584087203760509;
    
    uint256 constant IC6x = 11811217959272934414083319094084995449563949650427519060580194624534847030594;
    uint256 constant IC6y = 1697940144108270185009307986401142794462853772509759493513352943165391604731;
    
    uint256 constant IC7x = 18714113209507413896792067831199999865970477496506614335437300042271015104546;
    uint256 constant IC7y = 5187581738495436097647801908343565274814652250222063417370136114528615881553;
    
    uint256 constant IC8x = 8498570476020761376026618246558194750273369274424422902296986009560229990669;
    uint256 constant IC8y = 16784975830921805206804033003613531732290313731746789558588767450802255889134;
    
    uint256 constant IC9x = 6972912026687055976738980085355573754495952243949624207014975504060447749927;
    uint256 constant IC9y = 17698437187144483986515881232342160657640612199085508695114891001423428260298;
    
    uint256 constant IC10x = 6964480982231597637353160426290217596995533910586442265912459363575188786146;
    uint256 constant IC10y = 423205446567237592180745829383289384245027831074879477659807891834799456858;
    
    uint256 constant IC11x = 15349643419302741930243085705643490579525742343439327697124046726631244192214;
    uint256 constant IC11y = 15190423424809928428010567555341662695536385003645621482124328261885562343789;
    
    uint256 constant IC12x = 6935870584406406551309388832753742710494780324079559317440329436550677909485;
    uint256 constant IC12y = 445559517951916434217262803325472365025268051760843556857287634761353050882;
    
    uint256 constant IC13x = 20513943314745848828982976204466084445637442985685780255989058918553217321200;
    uint256 constant IC13y = 4687598294312611225126771540726473664043430441085027118705194548267472242729;
    
    uint256 constant IC14x = 12224734204609996096775772213572859653175415374732193567351960496703170584691;
    uint256 constant IC14y = 3321684364967678372354906174973948196728122071560198465238739595975465869097;
    
    uint256 constant IC15x = 3042591356758738715811967086844332863329710557040304219169322804002825042857;
    uint256 constant IC15y = 21828382557751069006497604091956092622427721123058278127145985323572346059158;
    
    uint256 constant IC16x = 16368661244812435242476279533710229482055443679152315438445574594588018883952;
    uint256 constant IC16y = 4418058270379104747697258608800690082344421780702266802382879753777727285923;
    
    uint256 constant IC17x = 13230451553351285166687075832832958915391322544649686931594379622799296166068;
    uint256 constant IC17y = 21324697684608896662225991986236450926029757860212514584513031994259827010173;
    
    uint256 constant IC18x = 17277891847800794175425041489235698667927095341906898847630265462092170366628;
    uint256 constant IC18y = 16411421821454687585031545685358249271299536541872118781092002497220624794550;
    
    uint256 constant IC19x = 1666238859871143806378296685778463733754648698974205838417765062318590631657;
    uint256 constant IC19y = 16932663315956694062697229589093254250043288621058678971755240704440204692109;
    
    uint256 constant IC20x = 1946230761550490397664501964110480180068201343029326270333981217104142360342;
    uint256 constant IC20y = 20587573995911289203333725728307908873365560217396177307542193295427882052657;
    
    uint256 constant IC21x = 10424989056467378713870250286451060397732694585769689989840394989670363368750;
    uint256 constant IC21y = 20578580426655913689017756400209760119411832663536448405892654248398136923973;
    
    uint256 constant IC22x = 4286017040579464554042847368056535418197770293838884054524760594143929285118;
    uint256 constant IC22y = 9583168719038359349266033151388416818406483894509003901660178467957054168487;
    
    uint256 constant IC23x = 15357405028174835184757196523213815206631993286685473942453292556227669554200;
    uint256 constant IC23y = 17406793412962084145156140064159899177134628214363901690116790536389219737933;
    
    uint256 constant IC24x = 18630982161975533415504005306802693211767359585327751640960180439928179584270;
    uint256 constant IC24y = 12311130380767801356460910039652479242645029588390358481605519431239967055913;
    
    uint256 constant IC25x = 5859738105163259204303257487899339549024171251763559855769472809882172262466;
    uint256 constant IC25y = 8962750251273412037454350594276457899986181791215074834739663215011870867335;
    
    uint256 constant IC26x = 5938018051747112342479639701787324401588761079180821086087033409332290596269;
    uint256 constant IC26y = 4259550431593055003759963365019266898443777464842298183155508984306163885529;
    
    uint256 constant IC27x = 1763026364525436192705229168053085578928116881276707495091123617077380544833;
    uint256 constant IC27y = 2694842849310682686825541812367310656840463537282197212474695133028881142824;
    
    uint256 constant IC28x = 20331794916621576247326566029201404720124374137367414719294780230717879322849;
    uint256 constant IC28y = 13341449193184743485002208301265070968456273127649801250761737984237462839547;
    
    uint256 constant IC29x = 21319666497074210422131884923277937674035839806925987148574341327623675153526;
    uint256 constant IC29y = 8855013870171608127977409265054906170199189076532377639734696841468045363567;
    
    uint256 constant IC30x = 21454244322275837236436027046634918947247606996876046082007023150404965015800;
    uint256 constant IC30y = 3171057536588882708978985787546620349058654518743081073520761571025915459147;
    
    uint256 constant IC31x = 790457528272163413287117787039991075378624640815762224757479478558721849543;
    uint256 constant IC31y = 12403344128923633826801876748835758488396175312328143643745254491751245682785;
    
    uint256 constant IC32x = 20396238690183099746938592517638577336321280378127323359709515599362427866305;
    uint256 constant IC32y = 13783854947566575793465023367772078391608759838405812941741506875571325205582;
    
    uint256 constant IC33x = 2642496884662484896023974307052998786489724496629239833155114639486332424544;
    uint256 constant IC33y = 1905940435754737594255219930221139159620535925831478247788835754652584553982;
    
    uint256 constant IC34x = 15506678546628335395965785968266302036358817917268270703528180551725650535180;
    uint256 constant IC34y = 10993560940083482338780034421691305767241419395250960266088416476474911039309;
    
    uint256 constant IC35x = 11028436812762693268377912069625396811619608022240915212583407735722559951099;
    uint256 constant IC35y = 2291668159644051890606088597984389102510444931592143511727585383104801601858;
    
    uint256 constant IC36x = 11511996031015945857892857501155564366464030879501470721617750316366706396974;
    uint256 constant IC36y = 21376664726688580749847985203915036613912381792760191753973182152454033406128;
    
    uint256 constant IC37x = 17551131815455112391712776967218924441278675487727625235719826467756119215041;
    uint256 constant IC37y = 18170947089790041457365871474664086414215078980137106278165008551729957079147;
    
    uint256 constant IC38x = 11971081718066640299192496115324761870221324709093983951457689456768253031273;
    uint256 constant IC38y = 19375163494870656710006953177237846974507850165487234992769959222308370701356;
    
    uint256 constant IC39x = 7383115567718301409978429012113406747888559722536022213978879208993342422682;
    uint256 constant IC39y = 20951839615489362231661995604072142551723976615814202447959692466382107114340;
    
    uint256 constant IC40x = 17146182724253742657027031324196310090359528709932048659131292936775872776141;
    uint256 constant IC40y = 11773591371105082518213452768018843460215092537497362199586050048779266414023;
    
    uint256 constant IC41x = 19798174221546853916140284012845934276231690488813078044363950368805926726584;
    uint256 constant IC41y = 16481969059154682169356163600460133076008980835813173747140939503998344674225;
    
    uint256 constant IC42x = 11072851330645612707069525467468722275121642378876649253980391967055844838606;
    uint256 constant IC42y = 19807745744029989763910330446112102981509428155360336276957010704846739082897;
    
    uint256 constant IC43x = 2690475725899154080540821718197321229794729546284109989478287284637965398670;
    uint256 constant IC43y = 19844491038006666784988708128260129344115187624221793157807876773891768900871;
    
    uint256 constant IC44x = 11091597333611922612011072827590603274528068670446464378193617720390899947457;
    uint256 constant IC44y = 3974690760807916054002221471209270658040620633487522157498903336658983484099;
    
    uint256 constant IC45x = 10127552062799742000722500289049016405169692095180216714261162649169475505308;
    uint256 constant IC45y = 2634869840292314172921925137042810176841606272226127827812544687840005295720;
    
    uint256 constant IC46x = 19327605309963887485224290660716072984991249899673995433145543487706840737114;
    uint256 constant IC46y = 20943372752276453807397652019389559692894979709490547466280473839573796937169;
    
    
    // Memory data
    uint16 constant pVk = 0;
    uint16 constant pPairing = 128;

    uint16 constant pLastMem = 896;

    function verifyProof(uint[2] calldata _pA, uint[2][2] calldata _pB, uint[2] calldata _pC, uint[46] calldata _pubSignals) public view returns (bool) {
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
                g1_mulAccC(_pVk, IC45x, IC45y, calldataload(add(pubSignals, 1408)))
                g1_mulAccC(_pVk, IC46x, IC46y, calldataload(add(pubSignals, 1440)))

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
            
            checkField(calldataload(add(_pubSignals, 1440)))
            
            checkField(calldataload(add(_pubSignals, 1472)))
            

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
        uint256[7] calldata i_z0_zi, // [i, z0, zi] where |z0| == |zi|
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
        uint256[46] memory public_inputs; 

        public_inputs[0] = 4613863539575941116572498543231254722517831745736020720337548681888374144754;
        public_inputs[1] = i_z0_zi[0];

        for (uint i = 0; i < 6; i++) {
            public_inputs[2 + i] = i_z0_zi[1 + i];
        }

        {
            // U_i.u + r * u_i.u
            uint256 u = rlc(U_i_u_u_i_u_r[0], U_i_u_u_i_u_r[2], U_i_u_u_i_u_r[1]);
            // U_i.x + r * u_i.x
            uint256 x0 = rlc(U_i_x_u_i_cmW[0], U_i_u_u_i_u_r[2], u_i_x_cmT[0]);
            uint256 x1 = rlc(U_i_x_u_i_cmW[1], U_i_u_u_i_u_r[2], u_i_x_cmT[1]);

            public_inputs[8] = u;
            public_inputs[9] = x0;
            public_inputs[10] = x1;
        }

        {
            // U_i.cmE + r * u_i.cmT
            uint256[2] memory mulScalarPoint = super.mulScalar([u_i_x_cmT[2], u_i_x_cmT[3]], U_i_u_u_i_u_r[2]);
            uint256[2] memory cmE = super.add([U_i_cmW_U_i_cmE[2], U_i_cmW_U_i_cmE[3]], mulScalarPoint);

            {
                uint256[5] memory cmE_x_limbs = LimbsDecomposition.decompose(cmE[0]);
                uint256[5] memory cmE_y_limbs = LimbsDecomposition.decompose(cmE[1]);
            
                for (uint8 k = 0; k < 5; k++) {
                    public_inputs[11 + k] = cmE_x_limbs[k];
                    public_inputs[16 + k] = cmE_y_limbs[k];
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
                    public_inputs[21 + k] = cmW_x_limbs[k];
                    public_inputs[26 + k] = cmW_y_limbs[k];
                }
            }
        
            require(this.check(cmW, kzg_proof[0], challenge_W_challenge_E_kzg_evals[0], challenge_W_challenge_E_kzg_evals[2]), "KZG: verifying proof for challenge W failed");
        }

        {
            // add challenges
            public_inputs[31] = challenge_W_challenge_E_kzg_evals[0];
            public_inputs[32] = challenge_W_challenge_E_kzg_evals[1];
            public_inputs[33] = challenge_W_challenge_E_kzg_evals[2];
            public_inputs[34] = challenge_W_challenge_E_kzg_evals[3];
        
            uint256[5] memory cmT_x_limbs;
            uint256[5] memory cmT_y_limbs;
        
            cmT_x_limbs = LimbsDecomposition.decompose(u_i_x_cmT[2]);
            cmT_y_limbs = LimbsDecomposition.decompose(u_i_x_cmT[3]);
        
            for (uint8 k = 0; k < 5; k++) {
                public_inputs[31 + 4 + k] = cmT_x_limbs[k]; 
                public_inputs[36 + 4 + k] = cmT_y_limbs[k];
            }
        
            // last element of the groth16 proof's public inputs is `r`
            public_inputs[45] = U_i_u_u_i_u_r[2];
            
            bool success_g16 = this.verifyProof(pA, pB, pC, public_inputs);
            require(success_g16 == true, "Groth16: verifying proof failed");
        }

        return(true);
    }
}