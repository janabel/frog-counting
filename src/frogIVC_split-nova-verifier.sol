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
            13732189032817714745853189550743233727834963659837355231052248431606397247849,
            8367420883967956574944456207568345285938981364489824005396060811546289714502
    ];
    uint256[2][2] G_2 = [
        [
            2884177954095897816592717128918884475816076724626942382777171019574410915692,
            8576504617255259460172800312441119294841516466247382801425833322160020314330
        ],
        [
            13207435093913093419202152602596807240568473127980031361322852298618656500963,
            7078092417035968118374976052907047875862119016683360327521257779161867848586
        ]
    ];
    uint256[2][2] VK = [
        [
            5336743080233298645512505781325858273777924717017143167851809561965855150059,
            2727912497788441327113432466451980858383049317329640631885965929449406863252
        ],
        [
            18073416460925120140830280358622220364021243599154573038611561961274551073003,
            11148963328182780687866885760925260002370488053952121390898429018336046927913
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
    uint256 constant alphax  = 13800582853952587482366517848652051642630301018157258972790755640644151185529;
    uint256 constant alphay  = 9860355697926479664889630654970320452970873215388136794669461843440920181736;
    uint256 constant betax1  = 13921706995470156341978041795971389505369051365896330329570281506650751438186;
    uint256 constant betax2  = 10909732746010564045018184056441298073962721392097421904961002421847358843202;
    uint256 constant betay1  = 18720837262001215269881078599993727608702420983675738427349433831341350279500;
    uint256 constant betay2  = 17190141624822966407698245925586553341347088427206593500328007755412784049769;
    uint256 constant gammax1 = 10568336249424871391486382732582915733870792155022724057470990604781550455296;
    uint256 constant gammax2 = 15422491869073548593420817456604630947007810363912650774957537076001152099929;
    uint256 constant gammay1 = 17771555640992278554985818906266726425408542762433055076926028554851078476678;
    uint256 constant gammay2 = 1173505370172042223019617599726760758312150398780835558510913208968578022605;
    uint256 constant deltax1 = 2979075726207700712028647245056768282435827653958783839924195163085425456758;
    uint256 constant deltax2 = 20543474020829045112179003312571933491469474716701621894014194408505826133863;
    uint256 constant deltay1 = 14874751579421206602504515798129146866455766183307960213790752086279680971062;
    uint256 constant deltay2 = 14284642326923570185345479720041608587831960140831633538113898382428713760723;

    
    uint256 constant IC0x = 18019934166135147547995898932623244501201090635729266645493551849860868378370;
    uint256 constant IC0y = 4228118153482029866288958164618378111017407163663732680276019458255010600473;
    
    uint256 constant IC1x = 2749941966294003450252188589731441025540211486494261425461818041395339949312;
    uint256 constant IC1y = 485856312902598838854736925582842614629067025156632214892720124496985116127;
    
    uint256 constant IC2x = 18163421920622471394537092724342806122264778613010878488853768323391172097612;
    uint256 constant IC2y = 361080607008626446104615752424416795392289449463594674383865122598757326995;
    
    uint256 constant IC3x = 2414001961577191987185163164054277195132139229894088511929610982962418226130;
    uint256 constant IC3y = 17848485011036648251730456435464851639629686035069864389024665944723672691469;
    
    uint256 constant IC4x = 540549367164754370255912774960895488879302463841233696696920927987589588669;
    uint256 constant IC4y = 14187008774147102057077633841170918114680064421468805297828424448200995007927;
    
    uint256 constant IC5x = 6903850759975465054428268262272491711320495517784996116983038894900560073497;
    uint256 constant IC5y = 1985098460939591603833263990873059323572804735516551893825733968295216729174;
    
    uint256 constant IC6x = 18279596608209337095034913127299466722488051840664569740603934556085836717014;
    uint256 constant IC6y = 344366842085056230345914831392928740947986252480371041672205517275856622025;
    
    uint256 constant IC7x = 18865831640619453864184333142985576382502653019933373172519302942298753490762;
    uint256 constant IC7y = 12648569440828614855019434448150524547062513537645633361806269164380933752506;
    
    uint256 constant IC8x = 18587417691124889877887738579065266572842461176653549199388703809131982833831;
    uint256 constant IC8y = 79789698815244833765695293497291412667294677258229933156727532912519720396;
    
    uint256 constant IC9x = 11472161922420695562831032339219391211346644409984710482751049153007458946760;
    uint256 constant IC9y = 19222558985582859945419857996264264593562507732992328496889902980586816488937;
    
    uint256 constant IC10x = 16744935228638823991284070606478811338427717612555965644308863148624197766344;
    uint256 constant IC10y = 14050566822224489519688599987759852935679689403411538729831353531911131755429;
    
    uint256 constant IC11x = 3579729073141655717700254843279886634180682593319858379336623569556910282051;
    uint256 constant IC11y = 16231451970195296647018517758095879694308812060517054719557127426690920469444;
    
    uint256 constant IC12x = 10724132433336353238462585606512401852463083434907053352234084933085479614730;
    uint256 constant IC12y = 7248195286566403344165444699986601767419403128964105691386442698659597652993;
    
    uint256 constant IC13x = 20013340378538997585206973311942224179945635391441028937367240174520270094548;
    uint256 constant IC13y = 13865665037882789875514073161645061044933078858167684069591245958368738588708;
    
    uint256 constant IC14x = 6538361827911638773720573851317081395178333661776454447762871382530287677019;
    uint256 constant IC14y = 2740155431041584818776205716806675922212073582789486124699419100161441989019;
    
    uint256 constant IC15x = 4371694395069729606727200128456869470228827021075327815762102545190835638028;
    uint256 constant IC15y = 742704129338645738195450934357849025475433320401732950013690572449693950993;
    
    uint256 constant IC16x = 13672451039051592305623319366559703456085375590915956584317777360367417918990;
    uint256 constant IC16y = 13282195958278286213632869355016252493647296361302848192335996147437432161549;
    
    uint256 constant IC17x = 2953990680319417113633803312026734060611780490004554568103847417022721051816;
    uint256 constant IC17y = 12151573690069999411947054103081032504406365735334086476741081846781274718867;
    
    uint256 constant IC18x = 4269579083712695118254723609080282155479845729137346026747974231162338275918;
    uint256 constant IC18y = 8292300817445295595031096727864061597982941673118806948773361010282565899945;
    
    uint256 constant IC19x = 7855488225741456028896093977551377618254608837553885317971959524256885581561;
    uint256 constant IC19y = 7041125894235931314472633080418295100161683976910624489454417346741978776917;
    
    uint256 constant IC20x = 20529188709020942193482486044235563925736026777922313498618182850750112180412;
    uint256 constant IC20y = 14529378560658235781261284115272326188706092304010222035425771402484407058082;
    
    uint256 constant IC21x = 2588699030184366072700328381875088153513581097829358107629457148517116479296;
    uint256 constant IC21y = 7985466991141170696170094436926372791974214128672083053530970947376383062174;
    
    uint256 constant IC22x = 7957722804065161127859842283299185121609903319531614811357136938078837842208;
    uint256 constant IC22y = 11713111409974154304086714041588702993514909883322711536805251105343850884874;
    
    uint256 constant IC23x = 3800368091263789312621215490768570813183690947710185193921646098355065419840;
    uint256 constant IC23y = 3067086404471022550966006896046667223621597369698671229983528235964629475030;
    
    uint256 constant IC24x = 2298931403724014241626381843418586432917886751574284264429555447590773978558;
    uint256 constant IC24y = 14221050273092060884496689002635869843527423128380975444087117616030322009102;
    
    uint256 constant IC25x = 12761516963412011064032672490889482539397608854703384754655735474806646425792;
    uint256 constant IC25y = 14981195034682237329271607589182659767700520002851999630213537443963541558647;
    
    uint256 constant IC26x = 9049136435098350584446147001876538042708382010346066105514048257051266616065;
    uint256 constant IC26y = 19101169824833256132695432381782092936687549863094142298434393288129297697213;
    
    uint256 constant IC27x = 21660613002350957977705157589844581933172022081217302149612392122119413914154;
    uint256 constant IC27y = 16260186598717862013671232507119373806271035268704664374622957300785516249514;
    
    uint256 constant IC28x = 20169926303361489962349034787369500759598531197597579708064319943039602053237;
    uint256 constant IC28y = 858275443816666088397208634532670030997713804995164001692329441670354619845;
    
    uint256 constant IC29x = 4013330476454791003955282806126527376207575328722239677242449234270943199955;
    uint256 constant IC29y = 11956391573348250453654055728341151154676626104559071927457036195038737231274;
    
    uint256 constant IC30x = 12173585387401503501919062183135161923424350711940084788288822524385407993173;
    uint256 constant IC30y = 15122167182258475778205882942971441187720097053505621730840996734612737423775;
    
    uint256 constant IC31x = 11689614614074416800796345457031365218190124252224832129781847866590902678942;
    uint256 constant IC31y = 9759443790066052560829295373385788514630261828660253721564217503344797354195;
    
    uint256 constant IC32x = 7495674215558829359516016160561278388632028007323131987637231591236097837204;
    uint256 constant IC32y = 11505437303246038920547396236349423019454685530611163809681370522198668272119;
    
    uint256 constant IC33x = 2302958864667211366312837590812367336133289886845219911983337482974619013632;
    uint256 constant IC33y = 11038029107398394297153013764788051684324868001548998895873624339696423111483;
    
    uint256 constant IC34x = 20041242829613195914091227151420069204412700454557987070111993246677705347684;
    uint256 constant IC34y = 15744303341755851527837594405173562950071125782419062700535380952812342786225;
    
    uint256 constant IC35x = 1258702413741581959171812918638239949088848115697499855666554437961425848247;
    uint256 constant IC35y = 9845815488330265531109300795341867090453763983865635700630009966273943931495;
    
    uint256 constant IC36x = 7752661254393701878173034778417824802114587682069694392322659122101198757074;
    uint256 constant IC36y = 14680829789470280676052335923873541993954165258007487997132293684473052293054;
    
    uint256 constant IC37x = 13849629252510129046153552877401260646526597967416073165472831685556744667950;
    uint256 constant IC37y = 6620006513137971966924648282956279688273762000752618064101934092495054843451;
    
    uint256 constant IC38x = 16333587299151124890279472480793479003284760220461605704348602747865288940533;
    uint256 constant IC38y = 17108865964465235632795666280895178071601184902373631909803626557814312759616;
    
    uint256 constant IC39x = 6124796044969201955667336475262875232826801848217196412113358152168624323103;
    uint256 constant IC39y = 14812986901457545613299361893186184030304752284144127886751020985646055839342;
    
    uint256 constant IC40x = 10559022947583553904182949722933944025382262756692307320846526058393552221236;
    uint256 constant IC40y = 19766508378462317403638345547705552907050434304569991017594020476940465406906;
    
    uint256 constant IC41x = 364745732162886779917240096203968317484576787852112741259710734592332193716;
    uint256 constant IC41y = 17091895048199410332270564099888864859696288684223633106147829822691752000715;
    
    uint256 constant IC42x = 19683849624307765263112949495263164415464321005417350063280569542794463366325;
    uint256 constant IC42y = 7985702399185379240752375134067092722601185197949836582516231563021258528638;
    
    
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

        public_inputs[0] = 18819453123134009743053735926191053673139905923832623289833235164387129441893;
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