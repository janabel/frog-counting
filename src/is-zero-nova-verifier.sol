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
            7659261304512500274242746289950417931827080893373498727740138885330539777554,
            9055301086370753640261320183936323064283311868955375561055741802691125318976
    ];
    uint256[2][2] G_2 = [
        [
            5472269937077051984333562470529815599310765869795941353018248851565192540076,
            3905248351986305874333613143492143352519764153974473428269122256004378609636
        ],
        [
            15847369686998551029170005524080488133680638791583339976932151466844505071606,
            15528478231165378596367219203582344159798176108630933613308821132007523287399
        ]
    ];
    uint256[2][2] VK = [
        [
            20160830782520922494851615633552550554108402570425769300507097126904800454945,
            1484326390310046424458769690147819643405349299016169568495669811216823904006
        ],
        [
            6965630255484052924665543168839657824363253341588860859749724779509941100316,
            14570168495953925489144809953375423687970489095313867828187144325012200875991
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
    uint256 constant alphax  = 7780053857613872995358136552196154609416833943371023757115708361337877070482;
    uint256 constant alphay  = 3500150728506084921008388101254953595901325606160123440673095039511676269952;
    uint256 constant betax1  = 10473233218907825883322352769387925668333805557250771343042892032950173645473;
    uint256 constant betax2  = 9407899619892045141089967028968566933054070058451171939182049895171812587283;
    uint256 constant betay1  = 18796930524259267421530006880672693846578703206847467976872248568578643098697;
    uint256 constant betay2  = 16166053081468244702190556047383896448513431461786813156445677050736392429910;
    uint256 constant gammax1 = 5044273191014444241263341842004908317241408180714689463319572056275346243342;
    uint256 constant gammax2 = 8542766664724145473471393414891265509868324844064640261697576831368248676418;
    uint256 constant gammay1 = 9545155993177333113854610237653119002215024856028023434470661742047224275627;
    uint256 constant gammay2 = 1114374520591409564007242697971950248878153852607092230305261879398752601457;
    uint256 constant deltax1 = 14795501590289380905678262283936353033459470043682456442964136841736045770320;
    uint256 constant deltax2 = 20607820728279811113329422225607621088933293936433113168128915591061574167864;
    uint256 constant deltay1 = 19012285142604322279245462422011162523218338962606854830371676577932979219523;
    uint256 constant deltay2 = 12976716656889987779049097560199399144344362330082671004100158703386988089016;

    
    uint256 constant IC0x = 18913703049012732918524339592106553010757138696759673570984516060218677007214;
    uint256 constant IC0y = 13318251693745982414718497738069043342453110765320109967322104998304240677397;
    
    uint256 constant IC1x = 10200066983569636055813277510941690193361374777193419433492999225805433472551;
    uint256 constant IC1y = 4740259474701248483257873115307800478022915061275929955208581769964509408913;
    
    uint256 constant IC2x = 10099152366853671835465578731174307446045878293061628762298152991966188538504;
    uint256 constant IC2y = 2203748660186872653903863464726316835461016988232755716785272971651075450601;
    
    uint256 constant IC3x = 3228497896892961962678223240460524658742117375805852039047066477382374344120;
    uint256 constant IC3y = 9209322558428659435230164336296667261204815406379110071498874950056562534962;
    
    uint256 constant IC4x = 1806995481826702387950162768542002049439994970079871795162876525181959797709;
    uint256 constant IC4y = 18372496010219642755729168676507901528489497073407658264239628748470243936090;
    
    uint256 constant IC5x = 17951999064394745341517958114354146159077733699904678699853025122868024866658;
    uint256 constant IC5y = 7496479271331068197588236031610060141475823260826252005637591383990427968063;
    
    uint256 constant IC6x = 15087864801310416795939647751199588462783778633098969148700811500967059985437;
    uint256 constant IC6y = 13025029070801689777072712068941721563974721033474786397176921803161209843443;
    
    uint256 constant IC7x = 5041033514109577738807701200140250465273401745032684590233158122513575933689;
    uint256 constant IC7y = 21429667518406976571840588349629002596958754814921440833833419599664634065664;
    
    uint256 constant IC8x = 13082353115808791530448536526669741580084248871205295206124053499141002546283;
    uint256 constant IC8y = 16538472910185588605660619986804174999476119641553056356454850259169253198188;
    
    uint256 constant IC9x = 9608085340849627633952875987099107660806139999833697640109102041029681583337;
    uint256 constant IC9y = 11158990579492753764404846140646558051845622679192960530841517096156590011007;
    
    uint256 constant IC10x = 7523250367964533046218389560805244374046329763657569638077344173845363836858;
    uint256 constant IC10y = 16426437676733453506444715894933632119119067489462086638833231444585231222066;
    
    uint256 constant IC11x = 5487541805304689171694215838041488989556479793226283768873771580720762062105;
    uint256 constant IC11y = 1167155752415630967658269794180053021316448682120498595743088931013432574153;
    
    uint256 constant IC12x = 5963814159503548414035269196610159038426236462555211199744894359683713877126;
    uint256 constant IC12y = 6892889849295619942762379115732278478786797840616014292673321143804139214869;
    
    uint256 constant IC13x = 4169395756099936358458966680559973685637906906177582869844524653383601712358;
    uint256 constant IC13y = 10428981225678967899889197955861287149084909015887272105850215686472771365185;
    
    uint256 constant IC14x = 19524613789780961453813344879091866315129215528881858253213888239207942110255;
    uint256 constant IC14y = 11078207316863246260156713441751902083758258726772808179496077245521319576959;
    
    uint256 constant IC15x = 12431499130290816510954015760980911514935382968221950035774276644648827997606;
    uint256 constant IC15y = 14130517291655399278800469521040901842614419381669718978401907557721507049563;
    
    uint256 constant IC16x = 3129553396621008546730196529872719282809507801925790937404633623808154225553;
    uint256 constant IC16y = 2125642265910078130391683263669922904723068332569272012831243375856895027389;
    
    uint256 constant IC17x = 6972278593397715602734726493462254759950127692144001332365367584082429907942;
    uint256 constant IC17y = 21355321287742088558023067418184550604273973400802330273057170896121554948052;
    
    uint256 constant IC18x = 11801869687075551787230286317428116540627568680041210598846078426513742278212;
    uint256 constant IC18y = 1905923975421164244977377239749637383346160856672563855544103900222185195759;
    
    uint256 constant IC19x = 3247907851181670397149561407220548278678771661657720929742130839455486524843;
    uint256 constant IC19y = 12063908057158722665284391949022679273636078487136288437877081843794871241540;
    
    uint256 constant IC20x = 19734563790361952725917414561922351347567817433654581350705379923777786123910;
    uint256 constant IC20y = 21379559535478495427130362512226897881235893476381574295206854847376808366676;
    
    uint256 constant IC21x = 929358248304181688872548581620159201339609239646033167611206096943176780275;
    uint256 constant IC21y = 17906173629477853346975836177541232731329500525375072956131024417268905354458;
    
    uint256 constant IC22x = 11518853796590764808913932204518642316688560159990844793023537585822245899644;
    uint256 constant IC22y = 15776277669443965372488548631196527173953642919859876875891546971155294165043;
    
    uint256 constant IC23x = 20498867535739904136949194906453293193530834757011224655106693300946570336805;
    uint256 constant IC23y = 12668902477066973605664680693199557124040791665417649247051493629366486350414;
    
    uint256 constant IC24x = 5444312538604242063846726578501278576836849498120288618378346477846309747526;
    uint256 constant IC24y = 3926376862310165350743706082249145876147401222501517630757189822559446427264;
    
    uint256 constant IC25x = 18623443835199237770190041944778786882197578691472897977910571016369282482916;
    uint256 constant IC25y = 3165632447239222079745050454608076620528178572084231012821443863026375743824;
    
    uint256 constant IC26x = 13014479775174026312674287503169056389149844975459965667268811236702894748824;
    uint256 constant IC26y = 2018858847392990791827908957234525715132355360085262169194392206813760237916;
    
    uint256 constant IC27x = 5711224524107679527595753018197216553115769160809307162927921479346681140329;
    uint256 constant IC27y = 18109366328402869269322259363974365994665697116393982189906759441198557367594;
    
    uint256 constant IC28x = 19638088250332311957734911373137488928372990541188419181358648811944546302200;
    uint256 constant IC28y = 11006121552433181478096218000274087575971250628535367102552483905755209389013;
    
    uint256 constant IC29x = 18017829238219141511229398727919959119842358953737412461821118574160376323414;
    uint256 constant IC29y = 19226959864450451885099591018868822494483617974191860534879945678607271265366;
    
    uint256 constant IC30x = 7231415050273502583121491844652358143331311501539624815302838198170122993322;
    uint256 constant IC30y = 19000313726550269049376291729797016180759492653987867751886537071444428583174;
    
    uint256 constant IC31x = 3338507296381390557816387773738879148079246202271619673871634771278407645442;
    uint256 constant IC31y = 13716099446226497094986359181277587521497522804920160054364194709149650238532;
    
    uint256 constant IC32x = 8473068864141527872446499179590480287463978515625819328457443004277294629394;
    uint256 constant IC32y = 2610430702790790205907568744154386688992234812055733128023008559299559097258;
    
    uint256 constant IC33x = 7492921453671223246017702645462966728325602629761256957938430347539305806464;
    uint256 constant IC33y = 19685405930854820296594009414159293954249349858671540115982396546185937512646;
    
    uint256 constant IC34x = 18390097505381014328233221152230602140251070727682568574468773820450392468270;
    uint256 constant IC34y = 14096995293712682741116657599037242981256057615585495740975262244932387543903;
    
    uint256 constant IC35x = 19730381804628697519445299987903298008939529000785347145372051125084915430844;
    uint256 constant IC35y = 18661292997191273658918975172458884475119832339620979603271299662585794808213;
    
    uint256 constant IC36x = 15049543299801764453610658500139476334181288600716004643584366719289884453215;
    uint256 constant IC36y = 9670363477210728281248026215992883008762263013107656157029362920759596861403;
    
    uint256 constant IC37x = 8392636392835240992828534447368280073546008510021760060571810048890451749501;
    uint256 constant IC37y = 16766060423366707489812321863942319548520640841442071129412093543356602130338;
    
    uint256 constant IC38x = 6617536803855156239024245253568552910426593786441176107138414955236619869905;
    uint256 constant IC38y = 14161701485548196615655699208330361483591435632114558949243140083547559672880;
    
    uint256 constant IC39x = 3932597156258744243011927152260113873654293547963275191042707544491663149875;
    uint256 constant IC39y = 19666065215967462466053766384122840041802643293788130007847537435853528208214;
    
    uint256 constant IC40x = 10060867214276309665598342569394186275560314403934723238034170144868445511620;
    uint256 constant IC40y = 1353409394812909780303244240978717145092448271578514935755743986373049690918;
    
    uint256 constant IC41x = 2587587818525317592944572279422502868657629372344376988390291989722015456400;
    uint256 constant IC41y = 1575259319180539821639557181241954928089483612937267701403938711630028964241;
    
    uint256 constant IC42x = 10184681391610268859611133397862211292548359803462993002781910445295229983391;
    uint256 constant IC42y = 10263362889864056002574857665033087110940740181507102534232086230805653843766;
    
    
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

        public_inputs[0] = 13901823348646815732046015891792119501073867968928656691709493638638937640774;
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