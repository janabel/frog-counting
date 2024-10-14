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
            14070702216460004021195164437060543783228245591252751935009966057749957940044,
            14686864236139296636710799650405317270011623524278098068441628650870143322975
    ];
    uint256[2][2] G_2 = [
        [
            7652051068335088756094184969202952894494019427647785326875996910937289245397,
            10076424382974911714496977370184029532616209653961886567776591516207593498181
        ],
        [
            3714606160682233797226337832316505907527108301244302465581162226574169637802,
            13207686006062369882494049754066091628471895219946984036350222145945506049433
        ]
    ];
    uint256[2][2] VK = [
        [
            10036106733671757863797545423549572972029754762564433636680434958208553410474,
            13306362571595287460309091940588410228450613330700473427264308382641864701874
        ],
        [
            9904648880586151946048698574868926269679252004219500242811450725767607594557,
            13238438518167288020649039193417135134450424316640040536451103589570324168841
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
    uint256 constant alphax  = 508389424852816835791559706772680374998140263929115044241408068582308121741;
    uint256 constant alphay  = 5507150537958782180068286354908433756394009055073499331657380732747576475321;
    uint256 constant betax1  = 5280948991256933899845625825545656908270144179500458848022068667659117437450;
    uint256 constant betax2  = 10960984389959940043878193814272088721544721831062023099128431274301527711695;
    uint256 constant betay1  = 2232000201101855150086534105653376131642943237411139722538551544889972348045;
    uint256 constant betay2  = 14073353587145562739837669137095681749027613620894724697169118306923442333152;
    uint256 constant gammax1 = 596866769252086409212621160258458531069973070711152972190212517710823914359;
    uint256 constant gammax2 = 4992668480914283239513962738837018914831634220781450665542716441995330977348;
    uint256 constant gammay1 = 5355512755695356066374672150972735348763753221004530644194344913773698698990;
    uint256 constant gammay2 = 1992756419149078633594506313705536638000746620365370183462842825845542489740;
    uint256 constant deltax1 = 4133099136836200830747161799641998173182893787888070270733654840425188339604;
    uint256 constant deltax2 = 3932335540274591266201786257535600904296920646360262902970026751458315634645;
    uint256 constant deltay1 = 4019541247270239499005526012904959717619409159002614264441794260825531487907;
    uint256 constant deltay2 = 14485127280998179351236674359043986993359182419743454457511765951458943902152;

    
    uint256 constant IC0x = 21371705960793613404039020538813001149737111281144643562874491233683260233844;
    uint256 constant IC0y = 9240591840726703258767662542603108208192664741690862569457076163424341699903;
    
    uint256 constant IC1x = 18954604312669223379052038994843368415644834757859597131790820287072316404236;
    uint256 constant IC1y = 4834207640283669109944670890459557901227184776798577466475942909219139968576;
    
    uint256 constant IC2x = 5885040659574646599441534457102385993328414960555380738856228073470644912814;
    uint256 constant IC2y = 16731884953167125297684222875846273770408382518033298514859707418092165599466;
    
    uint256 constant IC3x = 19018450391008732286957432058353441090657359637175693355972884708952890932178;
    uint256 constant IC3y = 18859139309886235431451441360210982579503939578251351338298574473089517886904;
    
    uint256 constant IC4x = 8250798001405764934122470237035364753931966390149657546980658450585807508380;
    uint256 constant IC4y = 295544291253758976520852699983345641425587356778370933183619726958902769337;
    
    uint256 constant IC5x = 17600185595029233766747735133884206761867287311465479795360951149661377747954;
    uint256 constant IC5y = 5196502810110254441536595939634137962545539325525390629052915184501821045928;
    
    uint256 constant IC6x = 18737206128712297184394037457830534331389105905996749404035027510682972327375;
    uint256 constant IC6y = 17221686869478816331916501062410656275326211953730339621665391464145208679535;
    
    uint256 constant IC7x = 14145801279307002991006861670166527271715493071007521835649339063575561315331;
    uint256 constant IC7y = 16482158154363897240379414959399059646609101092699011680201041124905178151879;
    
    uint256 constant IC8x = 11029303803335701928870815632867241016453928056456115194471488037595565920199;
    uint256 constant IC8y = 5871564967004651203912827911838547174890557180180873009431590335622555603543;
    
    uint256 constant IC9x = 15498553717913906545759393516184362973674026072136545485803146841451482236463;
    uint256 constant IC9y = 13992998629715109913455745447998062683503631797735879441210860905735694299155;
    
    uint256 constant IC10x = 20247303774435582117118977452856784670216534679561088658640718921760510655678;
    uint256 constant IC10y = 4460057165236300556323688670920630616298641557618925530901782511126588257187;
    
    uint256 constant IC11x = 1961127726396406278660228343120836213121821807815893971333159832168252683270;
    uint256 constant IC11y = 16473084725705304096804420508072930092771235659272937544111463349318580936770;
    
    uint256 constant IC12x = 7632089076043026786297079316383996002342341033820666033871718426948534822093;
    uint256 constant IC12y = 512516076460459829077767569246683875761106660920191474477388746008747341821;
    
    uint256 constant IC13x = 2033929386434242635251674866747123305406236372052398596088481275102734490278;
    uint256 constant IC13y = 8754855787421917733858616724817092436909069387543680980624336420325177857744;
    
    uint256 constant IC14x = 7086143728757563868733744910023518838377093453261657392352240716802685085289;
    uint256 constant IC14y = 2441526727010751797588712810304113255147725214514376477933261566604908193970;
    
    uint256 constant IC15x = 4496169823924519621891908584628066778325052782031919647498928070836694497299;
    uint256 constant IC15y = 18975529480584548375135464568270954405265604583074226340944163628083373765066;
    
    uint256 constant IC16x = 11619377217377391599656605160537694912122993301123332816120079622002100854571;
    uint256 constant IC16y = 2159893969681783334844388508092255508633726513943277369890172588014589612808;
    
    uint256 constant IC17x = 6031359427566145691081081681007627931009858559947665589745567775598661148840;
    uint256 constant IC17y = 11380965183980697813456836131210981135743807934265174881027868030471188973005;
    
    uint256 constant IC18x = 10290608889787506014785150082941320799493774176016602381543646906748834679310;
    uint256 constant IC18y = 18852045647255659422989440567517970942787786504946865912368621424999588796902;
    
    uint256 constant IC19x = 20098339886194565034450914155893818254413439451442438640542541233195433454862;
    uint256 constant IC19y = 9407079443061802193723953901959270321339964846611012573741603290366637719238;
    
    uint256 constant IC20x = 21188117918097586483721051516232375997996694569992273639111979215016253338520;
    uint256 constant IC20y = 18776107831613726642688774086723050960055588610341678328224601918490421215174;
    
    uint256 constant IC21x = 1421915013297730230887053749399828222299689233258859623327824627246136779630;
    uint256 constant IC21y = 9128758125268509858066516819696457450706508273437134099941779376217775345933;
    
    uint256 constant IC22x = 18263433355883044600296330879526294841430326934934177691113100622927670893131;
    uint256 constant IC22y = 15070796869820083226326668172625016649788378709514817248762539229312203898824;
    
    uint256 constant IC23x = 12154353707676839395153175349167352831780780382401699909317961594025059123652;
    uint256 constant IC23y = 569077811939296085233556213498130405969708490900932935813630750601613328959;
    
    uint256 constant IC24x = 4546085055976900037165923205367402517549031998069856913820390902884573359192;
    uint256 constant IC24y = 21300732412967699163296430373305529947703393162858213968301218596137309032982;
    
    uint256 constant IC25x = 13189359745696869305979388042931966205981857272570027447561921920144214363019;
    uint256 constant IC25y = 1990514847481244294561056871412673582999034186126709546480780581093428199787;
    
    uint256 constant IC26x = 2625533566195406328291865421447056613306198072783943308233905036160407990933;
    uint256 constant IC26y = 17840315782108578067670698955567363336483253197533542986950163863995377634843;
    
    uint256 constant IC27x = 19890113660463341243712267152382629537475486592641405425697997115417505218105;
    uint256 constant IC27y = 8051357251128288766379703789449845382177315033438771190116849831209917513537;
    
    uint256 constant IC28x = 14617149433984523219702147000214388178782934973917648746812234380265849755496;
    uint256 constant IC28y = 8696101451252425460854183769175870194470571323383427412959483156176194584130;
    
    uint256 constant IC29x = 20134191763541194756237632356608508307242806859744907043525678965989355123115;
    uint256 constant IC29y = 13346362123822886847293019964477915435804783960591152042125441124896546199166;
    
    uint256 constant IC30x = 10557685346833811762921841670918622263838546753379144307063861571300744409593;
    uint256 constant IC30y = 21096577482492856387580128318097068854076349547244622482826768160609471818293;
    
    uint256 constant IC31x = 18872851052039456284482271018925695056707937155857013359680114411433070553631;
    uint256 constant IC31y = 3258730547781404444888114446850866785110833084213468184229745267888941586677;
    
    uint256 constant IC32x = 11573835054177435945808995413418454385034823127877310030957862466366228976307;
    uint256 constant IC32y = 5611712372246946303231982356952710032279046284078427951462816113586405712210;
    
    uint256 constant IC33x = 19103355672280958836241622585923827239286131139081341271835728121296518756395;
    uint256 constant IC33y = 13775636359778375797958768202017979545039048160565567401462423154335505494;
    
    uint256 constant IC34x = 10840487805264003509981121083740970394491647644337299432419782037796853594288;
    uint256 constant IC34y = 13742198509041194484852400526930469207730875862241809716039216563102709798991;
    
    uint256 constant IC35x = 7286267582610217900593962423806823082753385824461453962555970116974256834145;
    uint256 constant IC35y = 13466690411733504032576984802275898639980439102092273920962006008410643720498;
    
    uint256 constant IC36x = 18079476528639894204802136204314845840056166754063765334859348250909926808356;
    uint256 constant IC36y = 20435750539279338822402675561053014384927262282848815021561282432853059975617;
    
    uint256 constant IC37x = 2322990637711274499412943898921370940735896408201243884281528884110330026231;
    uint256 constant IC37y = 823675541842984800872307916226650881380552959254466874129500637193679977696;
    
    uint256 constant IC38x = 5265221509006816626518642690991430952483116557263842072944865732346082414229;
    uint256 constant IC38y = 18173862943570520934773837034064566029364832885353699559723792887382993104988;
    
    uint256 constant IC39x = 11319643029584294163892720889233008663646923324804266611235229864663406793640;
    uint256 constant IC39y = 4120590861554079912054083764842500963538211558098346597298519667620968271598;
    
    uint256 constant IC40x = 12094389427897442233391502820209988207587054819145781015829340097219906120150;
    uint256 constant IC40y = 711667595935738969852513915891029390522453483802890967174236545878222895686;
    
    uint256 constant IC41x = 10861500101348493948318303334286763497304703648072245592549350845238703542293;
    uint256 constant IC41y = 3745460324936618220534174294354315785024261278760688020140746773371816061448;
    
    uint256 constant IC42x = 17937595717265238897263198067836003970199607635150605558989857022208413302042;
    uint256 constant IC42y = 19481494124653313226920867982906093382999179062874305939918363994940278910144;
    
    uint256 constant IC43x = 12404354578383701398361954648874213767299422382992741959580848313894666991558;
    uint256 constant IC43y = 3681055346442946456075864624209653665203621091677458235149138614991628837043;
    
    uint256 constant IC44x = 1655021652721533542800704066631028267139302770104407750477065648065146099077;
    uint256 constant IC44y = 6685607197327816041189402927534559856216550707795728417595093055800494498142;
    
    uint256 constant IC45x = 13082471880318125482226932563646169048990687073942175168282434685677784697462;
    uint256 constant IC45y = 11562552394551926598880117493235400572449849893652807717303177695558838051465;
    
    uint256 constant IC46x = 16450834739176582245644488863351570642185901137457413591383759547753582375190;
    uint256 constant IC46y = 12818968929671320520788095308166328838276364402014460847522111111426954374507;
    
    
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

        public_inputs[0] = 14156790554736099254687856826331987330515567995322373202655855338233432437582;
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