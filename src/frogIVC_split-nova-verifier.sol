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
            18548056711427939599634377282317986918348260882622809286218605090571627963171,
            13108127957903036933878448836024523431951336860240392537807685908810657392106
    ];
    uint256[2][2] G_2 = [
        [
            8454224397937719201535598832494012623231939017964935498740911112506688927133,
            13240261931761785137812371193477494065318913856717714435041037219131513955952
        ],
        [
            9998634886184060328516587723792829134282957055348404353089785206677702405032,
            19657028059945152892282430603396719005109067363827276635791635518060943247663
        ]
    ];
    uint256[2][2] VK = [
        [
            6731752976359347091377896201751004663092675662059013016355237771528982792562,
            14674118734740991724867134018219068771238432910610252869388165592314837624854
        ],
        [
            11606697188748034146479848193248083927250489602286606648431864061755211261102,
            19443055787927274315698685100045363017559493615911883504697054623894866156789
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
    uint256 constant alphax  = 13714687889035918939294244890221633216999667919249451001241921280661331869279;
    uint256 constant alphay  = 11297706829998379600066577214647627585828952489530841705622132404034032383559;
    uint256 constant betax1  = 11034984796762196199391421823232026175630546944603332272092232159735103872390;
    uint256 constant betax2  = 5662922449139242679634064483879275943503178218897128991936950273428180487372;
    uint256 constant betay1  = 6394331973931411235845395267676416741272141594869232851917806183875048555735;
    uint256 constant betay2  = 17234536927590508348658689137737805589971994330790034487566865646529465311908;
    uint256 constant gammax1 = 18456423524556936434282646811903658646895447518409595421551505317756754714061;
    uint256 constant gammax2 = 1820925038915243319523058654096983971900650949879845663664887534495241150574;
    uint256 constant gammay1 = 6360458684948492820333591633339112562274936617037160526976849704687845102630;
    uint256 constant gammay2 = 2344734442502551647104624829503257587657966401259947922482493819604680164106;
    uint256 constant deltax1 = 14530825986560070670477897437501601458757519555043777268234448643837037556757;
    uint256 constant deltax2 = 17260618128253702806984768617748999623332627783781469287170637334771222454179;
    uint256 constant deltay1 = 7483132094286265196720378024313822247912613201804826800123402951858981138731;
    uint256 constant deltay2 = 19100962477777109248250621408590130212556215294180597122272002351564084890080;

    
    uint256 constant IC0x = 15941908436950255781044039669936718335112117837087389554472074891930992023340;
    uint256 constant IC0y = 21771761292616135588495212432405119631959078132589775429180225463057141809036;
    
    uint256 constant IC1x = 13422014907959317302642730971865140486347615279807770930119854759420050456018;
    uint256 constant IC1y = 18110212382169046981778982750561474974738835126206325350116378388774797260418;
    
    uint256 constant IC2x = 15493242620816660404517175122024709952134164711411245108150604846504620526517;
    uint256 constant IC2y = 18918014521179651904726390149046686795840737542059830992480181741614630678087;
    
    uint256 constant IC3x = 18695343005163820273569205435385398542710291093155432728050762224073438289775;
    uint256 constant IC3y = 14745014171345463664552352347648623022288966661181487611576998450584228012872;
    
    uint256 constant IC4x = 2218650445328978280349169374237056048039187129168153638608256796929491502158;
    uint256 constant IC4y = 13254295010485125709352129577807700368071724361072323794814358033570805479842;
    
    uint256 constant IC5x = 4180873681575181136262245225646522902281779847435991312489595259007939183645;
    uint256 constant IC5y = 13456226643717619706774131494018294920247453070364487054380838691233578005638;
    
    uint256 constant IC6x = 13240294493052089683430183900323805926565192471346222151672457594281466251841;
    uint256 constant IC6y = 4026142423009048463518743189136259313299530734977070641044396915662844783926;
    
    uint256 constant IC7x = 12145727317853746895452219991532795113068069795161266447298434125416710342987;
    uint256 constant IC7y = 71770508369932252338740955011270221457774309413039123622874073103790371371;
    
    uint256 constant IC8x = 6757143877202388592502950372598382829614562187835365091401930571451447465411;
    uint256 constant IC8y = 9380556086487379689608147867004923810230015759047493911345041843378162458267;
    
    uint256 constant IC9x = 13448876747645564875738873384744640060624896838348131252080017119958622512086;
    uint256 constant IC9y = 18452279419659724940473838764944454598075725333804429615076471743466912309854;
    
    uint256 constant IC10x = 6765932528226528866516829829851480870484278062516788782802462780435222370435;
    uint256 constant IC10y = 15060210207738477717195329476866515049838163137938804360343526127561058982357;
    
    uint256 constant IC11x = 8109945406287133244839626013423755925906115223912799376494235414932484391097;
    uint256 constant IC11y = 6781990285449672049004235637055681930230867843826092397352625378978469664534;
    
    uint256 constant IC12x = 6893082446053557115533198746407375939080143020463273830675293480693111655925;
    uint256 constant IC12y = 945822214776128848399931444388971115542485339622233429322053176365565432202;
    
    uint256 constant IC13x = 15390765376635898007864375920050538685196939747580081553364020778945386774029;
    uint256 constant IC13y = 5042331510834911365365446149243200155643994641292240501218140432475270457820;
    
    uint256 constant IC14x = 6466878664771540465829577531685465063443989617306822202631714584016410654062;
    uint256 constant IC14y = 19288436761709169169160421035989246359456586284098810233287386960877055900030;
    
    uint256 constant IC15x = 2335569650226985834667364899306595375803784898768778197917165072988897834157;
    uint256 constant IC15y = 7534533929417024023808482823557790486582100354434194397800805862167211988517;
    
    uint256 constant IC16x = 8962421964404355788070950636734791004416869676496232018554954309497314949220;
    uint256 constant IC16y = 21740329965392117161706603148521342731288154261470154638185721823608454844070;
    
    uint256 constant IC17x = 15640638834379584756909581212458792430170224035177274816507577512918725028117;
    uint256 constant IC17y = 9673142622934517246745581371651534060588050463186060325273981583054096322346;
    
    uint256 constant IC18x = 6191939674187623702002711447192368456549932019148766852752206557062622242985;
    uint256 constant IC18y = 12652971130503022165165257362098050665122894010416267902581429525979847192669;
    
    uint256 constant IC19x = 11640826911866883834885937892645159063271305280800890373803487488451691833208;
    uint256 constant IC19y = 11919177285248539181069364896375265602855530991723926377081151200790211630319;
    
    uint256 constant IC20x = 18760933584291870330378516707524367844108821021430670783573818786050060262297;
    uint256 constant IC20y = 18899522414430020183968509117345073767286086273034176444297287643932326784947;
    
    uint256 constant IC21x = 471248545909358173475234724474781353397470326890853479318354089159519421788;
    uint256 constant IC21y = 5947344657999135193623344548491100678073169807471276974686785013244217167050;
    
    uint256 constant IC22x = 5959018868768277424128320277548045642196936071358851766541751699722735078241;
    uint256 constant IC22y = 942909479084763210091268359530178774561557288097042701990928505626997490986;
    
    uint256 constant IC23x = 6854350970122377440445829742058424971432304721659509814620410907069246887689;
    uint256 constant IC23y = 12199672246037696411432269624143549999337416605140048610978578805693945752556;
    
    uint256 constant IC24x = 6428302717192497195452621397712108673948074205210072363293856465789233299769;
    uint256 constant IC24y = 1486270004829454289859778488154922196077584735906487795684713815875944065634;
    
    uint256 constant IC25x = 9947279586964262812195898351536549762026625935993721015685378696935397084201;
    uint256 constant IC25y = 12674679820393384715537331327597289455561012242435684893860311897624642743775;
    
    uint256 constant IC26x = 14892596812222494544648806108952075976619787295055899184007513827075239772241;
    uint256 constant IC26y = 14288645136259323588982089107041287370332793617366273504839808906493425801867;
    
    uint256 constant IC27x = 11209475149548375122403782851292634863713526452765391453773223075461359274223;
    uint256 constant IC27y = 2540048768164901141825031981241939169374732499730955813581586938983660089380;
    
    uint256 constant IC28x = 11580873963613699693464722410080599351386881067939422427841183401031301418420;
    uint256 constant IC28y = 16935684265202144701901730636639195337097751895991049107588295916733542394736;
    
    uint256 constant IC29x = 14856209086782350814871115218653053931718937832398271934295862073364260354021;
    uint256 constant IC29y = 21777981241261801019902773842308445357565907984913121588846134314192418541320;
    
    uint256 constant IC30x = 3788995752844820598925327081919956322037275175360785134286518963288436564066;
    uint256 constant IC30y = 6905319537632051713163812017183675333629138728592339787457224173331080571726;
    
    uint256 constant IC31x = 18187478746534094292444805782475007779376739520595968805463133840108490528917;
    uint256 constant IC31y = 10597254376938158632961597268383911793029006865594099694747889296391637597400;
    
    uint256 constant IC32x = 21884615966515471538871101732140212893523180707538441497487529366631753441570;
    uint256 constant IC32y = 9126367499391103392477364904042614079624674706412264669925440746776954085707;
    
    uint256 constant IC33x = 7096089982160127000999098974864533172825613676319714513604180806863481343621;
    uint256 constant IC33y = 7721970377166888105392471992962435271593928340548259656888977914130086777966;
    
    uint256 constant IC34x = 20750167241872215772651163557223406729302279563132198685690388442880280137219;
    uint256 constant IC34y = 7061988105002573855316737505511077001600219005200541018304948831606672831864;
    
    uint256 constant IC35x = 20535044515034769350278386341535991209910258016228596657274728992226882799981;
    uint256 constant IC35y = 19786444147048697317640869921663789548063781627829784600880370181767834786915;
    
    uint256 constant IC36x = 5527730378731530388214476533163685150669416187741816565942969849167513962455;
    uint256 constant IC36y = 21802403572853434372894971427847778251689857327276489722877310075207983005379;
    
    uint256 constant IC37x = 11871057361224193712465515481920536904653129637856815179236699291973924544881;
    uint256 constant IC37y = 7327473280453672501330453120169293875117272642609411312290546103535697546753;
    
    uint256 constant IC38x = 13006135008537552327075513070373226670868544335791963935539537149760997261200;
    uint256 constant IC38y = 1615182442139987158038623431862846214965267837227046718949493618977492436864;
    
    uint256 constant IC39x = 8971133842145525276819665049331027112208545149948282526131826557968973764153;
    uint256 constant IC39y = 2941958553599302771824467116029459290629316531649132568109513596455375791512;
    
    uint256 constant IC40x = 2886061678416695547402669783148153028563271892621155657225460582564031279898;
    uint256 constant IC40y = 1890460371246885589124881481598747716564186721244512455337472867832745764196;
    
    uint256 constant IC41x = 6371348395535385093188629607499321001985362587994594704386450099696452452811;
    uint256 constant IC41y = 8125258455957397809656520028841361618869080606587732883476111983466309492984;
    
    uint256 constant IC42x = 18187092239429746170355012300210541563382782693701699704058291119287837065568;
    uint256 constant IC42y = 20410188157920620909735356947217765620201674537603123108971589831957961350359;
    
    
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

        public_inputs[0] = 16487042634522657151223183142496965902980701817182413098120947446780735328904;
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