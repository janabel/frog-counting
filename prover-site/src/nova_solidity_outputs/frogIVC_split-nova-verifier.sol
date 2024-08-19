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
            13987405534281410489079631774214183265311670848925210099302625429690725021118,
            13755076423709733475263724587742461283740737052793268305058597645636941889038
    ];
    uint256[2][2] G_2 = [
        [
            7751655579372822267726190907734688355855896566924853378051056232605063463712,
            8409841128797129980381471899024241744967839209352397183756631294688847987306
        ],
        [
            5495681800466459449233148470761878484013602062534068752582940699693381367725,
            9893471763868919128466677793102273995465123220315656950347213707985560712247
        ]
    ];
    uint256[2][2] VK = [
        [
            2559969199509816733924407176373868870226128417172397265924139778909044963334,
            6351157376878690453614359336079284243053620147165406331634756412855835121050
        ],
        [
            4400921900002899371012800951871838791352961002629087742252906259992535639949,
            3907848682857036956600922495966512666354706768046921688714911192009288298301
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
    uint256 constant alphax  = 9494392012923916901737613700020263636733953782662951195325061747333621456110;
    uint256 constant alphay  = 14532581830752133779521214049373254576519333513581339734597190237640371986353;
    uint256 constant betax1  = 21783393872067316745220825151107143461648542128096314610558240188882929092080;
    uint256 constant betax2  = 14192630462579896813099816744395579688859260675158895657734096503753023505868;
    uint256 constant betay1  = 15817232829918250213346295049459736584584939178983331247337954537172435517533;
    uint256 constant betay2  = 15430609818512250422490781367055114428056194004879873433083000783508025935574;
    uint256 constant gammax1 = 18554209619107657839409107634460530920340834096986526324457266117084326115872;
    uint256 constant gammax2 = 3286971575146577949056703128343420690837759841506381706370543265073049832370;
    uint256 constant gammay1 = 18293996194379387107699605435607480848084422506441164693302162724332792802398;
    uint256 constant gammay2 = 19577096071271215554889674144369960870118912662590577866347995477760323291827;
    uint256 constant deltax1 = 4550374324668832472637715682211190935099975179715649707247405459542056197942;
    uint256 constant deltax2 = 19708783656273347255368848589947550832547358948973739195535715782321395265212;
    uint256 constant deltay1 = 17741837027377583008994059710578426079035469187722366954177103015658737243154;
    uint256 constant deltay2 = 2615444340046254797508565149613436753517838618778340769503836516140029777819;

    
    uint256 constant IC0x = 21368690890667277561397617406092931124312358058456993943069896848610513453146;
    uint256 constant IC0y = 3347887392884432303371280569182815481700281684329336918998519856836572926594;
    
    uint256 constant IC1x = 6459584090891388792723218358883286114221643793868349882838744687994682473545;
    uint256 constant IC1y = 12108289381452172631583277755110643028453693864311932395514249888134372490895;
    
    uint256 constant IC2x = 11984056018372656701004247432282042851207400456839702964728764530009497290350;
    uint256 constant IC2y = 16270697376418052531099493826333808998960138879107535113474988709858337397741;
    
    uint256 constant IC3x = 3708578942351135440711330058689428616492631070614338718044206624164340638884;
    uint256 constant IC3y = 16482031358517181705249667716551590097351913205296986904910962375412507577801;
    
    uint256 constant IC4x = 11805324861868628304499834821461445367169251242199346326709444984387024274303;
    uint256 constant IC4y = 16417813528549240794588328047068580571242305948623526668548187175618188689813;
    
    uint256 constant IC5x = 14411142529505282785784129469452568094085978304893901583729802107626173749276;
    uint256 constant IC5y = 4410674701057111453570053009447860951970294686029433046561999227901059050440;
    
    uint256 constant IC6x = 9998986635159033865258578010792696613275505027130295093573103554738359671054;
    uint256 constant IC6y = 1116659323311136938381858033746041311470021829837315032295237015675535513663;
    
    uint256 constant IC7x = 9327889816975099229094255094661177984319410954472598316255281183463611740006;
    uint256 constant IC7y = 10904652230280884878810364983871200511111557488568943620563892455977986609778;
    
    uint256 constant IC8x = 37503259936439078409506176300987653096766201766080190719678619433560880418;
    uint256 constant IC8y = 19730108576670438391895516433973660065825241101921461028582405976486478058176;
    
    uint256 constant IC9x = 6736844299069013001457823045445036549318498577392738307636318569005005305020;
    uint256 constant IC9y = 5724286722968462687996158442666021342065790963668370539303586926103418487805;
    
    uint256 constant IC10x = 6303279447739523829705787296745113607872379654493926408000559736324448045101;
    uint256 constant IC10y = 13029605788502675444536237803080611753335510706628781950028442821176891472456;
    
    uint256 constant IC11x = 1819602425078845169644890842116853577048975635293164855798299431746064915789;
    uint256 constant IC11y = 3029862860691014894482816732781786008688120604116019240958266994178855966128;
    
    uint256 constant IC12x = 12792780198627940371071652364842465102573967471325534835136217851668855105965;
    uint256 constant IC12y = 10188725144558547579449719880083554257721195932587706664097063707976518422906;
    
    uint256 constant IC13x = 2400440091160207157419616892016466375235042895475361596044121427722735818093;
    uint256 constant IC13y = 21820003799324861211977970444734862252191349447446654445303661999333284216932;
    
    uint256 constant IC14x = 901772461833709210413561062004799330492844630031785402453067214079447023156;
    uint256 constant IC14y = 456491851669749563815981874095246984033383588044050004194554417402715446138;
    
    uint256 constant IC15x = 21157998955962647824523270595991813207981509066211904932840955401623775706519;
    uint256 constant IC15y = 5748530870400924922759578477099140178527143471165135976162152902354604542980;
    
    uint256 constant IC16x = 15298255205871155910392338351126859132437349662477339767565132797304137019593;
    uint256 constant IC16y = 17605681978944465587167446145909061707095212726476122001915240027979137257699;
    
    uint256 constant IC17x = 7188197452938268840432688232005754166229580502743784390068067085671133490237;
    uint256 constant IC17y = 12368649617693309312490943130943187808190424345580797120460559225647011124682;
    
    uint256 constant IC18x = 5654108208224345523926870216515670450272724572207843458795078867272545377829;
    uint256 constant IC18y = 3583966320582107178989707236243232670464679628210259481377975920781452720856;
    
    uint256 constant IC19x = 13644207826770278328634929620262930641087428602881660885396248999765846127674;
    uint256 constant IC19y = 16483763642396342050489751544596967348341894632924201940712481150500384753483;
    
    uint256 constant IC20x = 6152121138413345957868402092124536323886086639631111691336543969091852947921;
    uint256 constant IC20y = 6812281239479378552078975343610738280622753918065504511845037585889268715874;
    
    uint256 constant IC21x = 1498583464183699148691489734463121451624457684534451508784688444109942795422;
    uint256 constant IC21y = 2981700881780012127932635107340217788007982496542208890355823735550292372120;
    
    uint256 constant IC22x = 910061856866226090984752977282603530492439605277134513927667264402832088127;
    uint256 constant IC22y = 13167238872578229339103872677899894043191963619990032949038490151121675710267;
    
    uint256 constant IC23x = 18477855726972852111547316130971782661818410819118972149655035160369954292675;
    uint256 constant IC23y = 8591042478555157290338714668182511864229360863420869271542170402540979875224;
    
    uint256 constant IC24x = 2675824057928933189687025083038739952693307636724852739524956209230687149316;
    uint256 constant IC24y = 20350556079974548193771583775761211005107266069266921712617133398388914939555;
    
    uint256 constant IC25x = 19480131591661292940757677263835136130704931473425015022410869380997178618870;
    uint256 constant IC25y = 12732550258208563028926291627194236056100224838554495811896691805187562958773;
    
    uint256 constant IC26x = 3277644892204004643709360036515491125229567017780508120537870717954187118194;
    uint256 constant IC26y = 6871734166700523353092534855173053443202433375901611607130241696505516822996;
    
    uint256 constant IC27x = 15105797579288098640950721548570352756974844554645267883727701417171598962868;
    uint256 constant IC27y = 18333052561726818151101599495758941092891769281937776753924060504145591176634;
    
    uint256 constant IC28x = 9817138934551806233895934942840189461001317856007038329695101329968063837301;
    uint256 constant IC28y = 5673633420078756326216109872945654894175646096177666957102204425170349607509;
    
    uint256 constant IC29x = 5127502672643237301235483098078882798108778585486693406957245200436299014279;
    uint256 constant IC29y = 4556080424699098356083819126693444078687505566725354064611044606670535370453;
    
    uint256 constant IC30x = 19831966806004231908273771786209466430473721292072592246837438213208146613345;
    uint256 constant IC30y = 12166946832781147346252269462239215038597815661854395448104351585948489282108;
    
    uint256 constant IC31x = 13349804999983544595087332966631080232001526102547831650307812974465745460118;
    uint256 constant IC31y = 15032428326334199209050830797374481918570095871795692320632614400678311815743;
    
    uint256 constant IC32x = 8800203357842379446785702976513080123375094250083546304687911503530165744192;
    uint256 constant IC32y = 3814652969175080770933280063482107118126626926702115272871433398629079734464;
    
    uint256 constant IC33x = 15394929500054129681362028399920645656255615496383400808135180737114611265735;
    uint256 constant IC33y = 18113514616112415445735225870741993129112055193299562905347181842636891779756;
    
    uint256 constant IC34x = 12572100227010990130979849290940516925599778790859809527929693829005949668643;
    uint256 constant IC34y = 14787911620780221995887410692805764793829587040331921476634529679540841062503;
    
    uint256 constant IC35x = 9384238667357976314911594778414194250918578535604536442251955193226378981481;
    uint256 constant IC35y = 6599919728908983568047040826543572013939128456099733833871465878784879240380;
    
    uint256 constant IC36x = 12310297571554028944450023373406489694386278987003429466471370146887908870592;
    uint256 constant IC36y = 6311709586212056584783719081121675248376340609256756612296045438061834781951;
    
    uint256 constant IC37x = 15589716088912906302096111909475418868250190716976771174199609775766532647329;
    uint256 constant IC37y = 7335075624352709115144070240484809266164972838447759446991668985030290829423;
    
    uint256 constant IC38x = 2258833696845304785870943969451939929148050581426758358182356860167481155537;
    uint256 constant IC38y = 3189277125649223050718900975516632433835292733276204199764082685157300781324;
    
    uint256 constant IC39x = 19488063997584172862676987576052394406537214014355829936209610181894308678353;
    uint256 constant IC39y = 17519682413572827592322041923205667385698442082358059304441061111834659683370;
    
    uint256 constant IC40x = 10734772814393011219258597290099693309092067401729960983693502402649105986548;
    uint256 constant IC40y = 13500383889398884481368084380827137327207273958108705520363239616789420211097;
    
    uint256 constant IC41x = 7502537300082827527994111148613476909615089811513202925737196442673190281275;
    uint256 constant IC41y = 17043580880971165123088370985999987119562466450961451882159331083193297671645;
    
    uint256 constant IC42x = 506978207353155051969116329310239448297984583134923036576643298310370997015;
    uint256 constant IC42y = 17733850490926209980483984961407068244954243629757435208544351178152664824731;
    
    uint256 constant IC43x = 11157920328571823150294853937910962953803812793279927970380017703657747696051;
    uint256 constant IC43y = 7632816701806587246076936914442654208406457496271827377046430969603871115802;
    
    uint256 constant IC44x = 6978667584205031586281358781701297010377538460588072074497675088168669529876;
    uint256 constant IC44y = 18976942619734705378094449316347493762197540884972703658151940684122691936352;
    
    uint256 constant IC45x = 910170382588867661676633293449763066078732305341624974515390134266095880442;
    uint256 constant IC45y = 3680982901234499310329687394283823558414152220318143723597434100367414806308;
    
    uint256 constant IC46x = 8744717151140606297981738089775255149872576613149131100970884287024580715198;
    uint256 constant IC46y = 19947400746928966745726811628799751331773139997146789618687831493240377280213;
    
    
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

        public_inputs[0] = 10944843602903270485708993084259045132282417161241110202407102415113784140574;
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