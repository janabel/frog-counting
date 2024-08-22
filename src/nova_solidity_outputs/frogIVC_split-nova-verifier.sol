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
            20114534159575247788681452854283833319266306912283244622246934186985542734332,
            10839432449484023296805792707901153658998079235674679722621248146293718579740
    ];
    uint256[2][2] G_2 = [
        [
            4608739104355955621835501006163998080745315422263551835121767387164635567066,
            749918526159995941385627149272093859351451340173348517031378697044981222615
        ],
        [
            16793994137889868164842973153031099352925555221540477893272654435765945458006,
            4050231408220980863368525862456061989160378261614084050032089875770084780555
        ]
    ];
    uint256[2][2] VK = [
        [
            13908687765000204263387150694825122860702287846992548631003859702681633096773,
            3537066185324820413694202249063532560540951334777347219379026263952470764962
        ],
        [
            20418535610690985379317054087508615636831503212927681904647685753156454969494,
            5979473810952145223026318361874391190018933213252849115905592944135441748191
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
    uint256 constant alphax  = 18659280780364347995792981478407887551539604024143433299947873520124282774731;
    uint256 constant alphay  = 1103543952071697337430707497664756787355157165035124104997361183854643793586;
    uint256 constant betax1  = 19975142237823693343519810371077628115829250821588694182626096611670802050798;
    uint256 constant betax2  = 14141036587402053347850728656564262116713794817999269734759810517430149755553;
    uint256 constant betay1  = 6990257004297676679135546478003767658511787908213680223371923277522549997619;
    uint256 constant betay2  = 17973507328325687514488683241570630228926057844678879307787800129022424121415;
    uint256 constant gammax1 = 11613106855852289258622267996180814158809529742774181199628761241160993697529;
    uint256 constant gammax2 = 9001536208103102027172953742722183864884928616203983594296926330352939019994;
    uint256 constant gammay1 = 15578501641725008454198206050129445877533970857539837590949656412236548420602;
    uint256 constant gammay2 = 13280541535945221525481176007762929075059656590396901918968180065170957739606;
    uint256 constant deltax1 = 10948594080733705986164698012431501637456803253631838137504396755554366596760;
    uint256 constant deltax2 = 8409386831455829762307079342250090990013824606224275860053787947285755120973;
    uint256 constant deltay1 = 5320499381102179249274582229983868624773287587789793715711625452442153436039;
    uint256 constant deltay2 = 14200543649838628194718760287834049212047151644595656777226960100186093022166;

    
    uint256 constant IC0x = 19912875546870326808117139245472245808429078086712948274350101391036249474658;
    uint256 constant IC0y = 14789495932168448558398369477974976960871995381565228309361888526784994805971;
    
    uint256 constant IC1x = 6602062616537693238485250779480463270455020423632535165499143671499247514347;
    uint256 constant IC1y = 4397159710482813791150044220248651666128934308501873484466114488231631855603;
    
    uint256 constant IC2x = 928908021948662235309814419290696935990498763995648293024751494669834223178;
    uint256 constant IC2y = 2396364366629732832680367165609109206825755826722540395913864491282841995887;
    
    uint256 constant IC3x = 4524997678073178027805941592486044997521099508538366773541118980262272314737;
    uint256 constant IC3y = 10046273669898694081654932695174101886577522970857892935017396087640657128865;
    
    uint256 constant IC4x = 340518044903054667552490871674111269312077147927225280055963734145214495013;
    uint256 constant IC4y = 9293961000653213904040150013701189582938748676065519696733983268460260263648;
    
    uint256 constant IC5x = 18486834283996651948261035835581443390386329169105140267277569185810607379406;
    uint256 constant IC5y = 14624063153371511681974582127281537537697478176935485818683182826273218020657;
    
    uint256 constant IC6x = 14733908539325376051705823614417755362181767381593725154043698142937093866075;
    uint256 constant IC6y = 5770364657887470171994432940191691474980275240844073574432482307421971270489;
    
    uint256 constant IC7x = 2591925273798256876830541981043243150192212004039734214791553668952046081526;
    uint256 constant IC7y = 20948784173816936812196174565872106876853598603913946402914067669198993737069;
    
    uint256 constant IC8x = 17770028078693751809553741480848795751975825932950454988887686291500437571734;
    uint256 constant IC8y = 18525455453412364486867330941933818396814815268411546517559167916110959357423;
    
    uint256 constant IC9x = 5411837535541508612796073578957407045702219166550442744564534043810037834932;
    uint256 constant IC9y = 15427400004710116914151822420076196746341997460965494736245017368199227932454;
    
    uint256 constant IC10x = 5355769422190591204358051820126547806717775026902028202237901227142729094075;
    uint256 constant IC10y = 17129939904244234541697594676780423442499557553279466658195703776715957732652;
    
    uint256 constant IC11x = 19751087871064964852752782355704008243096952338673318490055463132604749177995;
    uint256 constant IC11y = 13485401808066149323049300057800514106927124774340922406300342307140242903402;
    
    uint256 constant IC12x = 7662274994043991079500023324900699055288636313918024736221064947821755539687;
    uint256 constant IC12y = 17483946273368828153245580549322263125096838346126425019861675790452892804228;
    
    uint256 constant IC13x = 15453428568040443835896654269088190510226884715928822591070988280795629782055;
    uint256 constant IC13y = 14667136326109682616170135007851364367829616937176599248701216164786775916806;
    
    uint256 constant IC14x = 17526728998343677055659653198028592575912290036464259381434470524763740924311;
    uint256 constant IC14y = 4969604322098181130574743337821520530127489706104662447850828268535688173415;
    
    uint256 constant IC15x = 5427734093661446252842219686870566902875266216694615303901840567715877134580;
    uint256 constant IC15y = 6360639569493828932936072737126735173612029732827470844020935021277449960921;
    
    uint256 constant IC16x = 8721302120396709222380131698217751825930024176160815231855653652309125413716;
    uint256 constant IC16y = 16420697434704633071707914887088835482494660545830924329133254191893303418301;
    
    uint256 constant IC17x = 11462592955455223229626877451574060872735128683648740410590573444991726602529;
    uint256 constant IC17y = 8677544354058609685152339125275830384015706495005562361849746857687784432526;
    
    uint256 constant IC18x = 7249716083925916184492651499847135297643521873567117380094047754763706912466;
    uint256 constant IC18y = 13544821277966374135513089502946214923077470321117641751558391392497281401841;
    
    uint256 constant IC19x = 13181413086688272842062583257465238772928138043479872062037304642156386048853;
    uint256 constant IC19y = 15355514290772300393881729000654342527082928733075236038276325018976946004128;
    
    uint256 constant IC20x = 16025254619618957242305385770923360322269144177637461996207305452479771543869;
    uint256 constant IC20y = 17354219347068539572422219287661221802909453433193746121642338855071457743750;
    
    uint256 constant IC21x = 1478521667133492514511143641547172932219893605963785898728270138698178635784;
    uint256 constant IC21y = 13578531615855044606900771957159754278313488940613928087133596770069814875981;
    
    uint256 constant IC22x = 17606910014702193630879306383592701737816134626463122693705722142859712643345;
    uint256 constant IC22y = 20101166908735639624657384999728079328509469439753712003357053699935729175949;
    
    uint256 constant IC23x = 13559442830867528436461341911273585977170706378911216145829929842022200262536;
    uint256 constant IC23y = 11619646222570365051848500865808786837785141464874399299116429363139686206708;
    
    uint256 constant IC24x = 6696727199610901639121259371225942123121807914994001655804196980371189765691;
    uint256 constant IC24y = 113556406445683707873682982004135261073915284038940762324723599228611371717;
    
    uint256 constant IC25x = 3867062346152924713106217662903955831655251531874772515400280563575960101705;
    uint256 constant IC25y = 8378991380341440096392624190861769393653392225286318088226675866681773131621;
    
    uint256 constant IC26x = 19149940731636004315864156205206891202403273940757599908885591119765260599771;
    uint256 constant IC26y = 9017034211540031689400769257621046167729518817242840403823215216451349995578;
    
    uint256 constant IC27x = 6910787770436611301006931926149300394722923213766645476322675429333201482825;
    uint256 constant IC27y = 7036753930123596994917233690016027198505429088778895117952660856014716076092;
    
    uint256 constant IC28x = 16945995716393293362981364746136343796872279246072907478744533304566254327562;
    uint256 constant IC28y = 8818446537797776398040534151377427265311386629981238729612373298103770957182;
    
    uint256 constant IC29x = 13810062190544616638712899402243598550130021394364933508938151504995231875374;
    uint256 constant IC29y = 571840835331404894792980991328459607080641577178425397158472587127896632761;
    
    uint256 constant IC30x = 14586921732319927333660410093565275754202846015426802490956810379193646035328;
    uint256 constant IC30y = 5207822316674108858667543720039202978018444228107470079659364269152794289191;
    
    uint256 constant IC31x = 15805446966308361000284436784084621325084453325222081110660629943102051615492;
    uint256 constant IC31y = 18723900300152821431202759341172256616951388822853554288762021269215335415185;
    
    uint256 constant IC32x = 17778926221787623437443740302073571303447867204711560239868883748838002904206;
    uint256 constant IC32y = 6623279307211047481447992169526770475634730964862292131182629585994803488907;
    
    uint256 constant IC33x = 16236938112910594497516294924575165201746304475837952322614457003432110540225;
    uint256 constant IC33y = 9529152142199457901100710476884726013508659123720431825138476815987195259755;
    
    uint256 constant IC34x = 47523133195370621518305027160632210532096882325188064250621687224255148505;
    uint256 constant IC34y = 10532832735789228054127872417496647078460485649612504097741333457356309355888;
    
    uint256 constant IC35x = 18251482441208596070559854020322680958045304194122675044215880104506128545553;
    uint256 constant IC35y = 20513086267979779368201481950359014343737570070245206021999924029056284616431;
    
    uint256 constant IC36x = 8165038284864590783058112077129748213356296817827257799962952885848243915818;
    uint256 constant IC36y = 1869986228133778291202499563529990809554552705563756790742166404241156954322;
    
    uint256 constant IC37x = 6247364667712689164073325112208814543201525026060580641588097445687550662778;
    uint256 constant IC37y = 18052951946387311816648154650871686127630875333191076958771799694836214560436;
    
    uint256 constant IC38x = 21780371514579382647594542861857926795891666910743513498552479246327848529746;
    uint256 constant IC38y = 14268089317695095171324743230498037521926605095645753829934908742540750899174;
    
    uint256 constant IC39x = 16259131934049584354774008789825224935659585888926962801987846693753009599386;
    uint256 constant IC39y = 20474780341452419535904075118511317339468923679879160665645452738221402042705;
    
    uint256 constant IC40x = 3201175462791888773231676454577806664796848292729706080831197669962472399584;
    uint256 constant IC40y = 16582288089814328184194293902667005223250147551217063141303153660534851375912;
    
    uint256 constant IC41x = 363263432994883381898245959154018645398626990581269942556652653527633806445;
    uint256 constant IC41y = 17947292951935003750069479263554017500011863738354027667159753140096383568544;
    
    uint256 constant IC42x = 17015478563971582053212285955921290411638134868209220399542630263504195791188;
    uint256 constant IC42y = 899275515594973845269358820440625946074336998624645870011163088534145108614;
    
    uint256 constant IC43x = 11398652284665649376120127853485544046611070810145820292507193748082363788255;
    uint256 constant IC43y = 4745950658881446112750324106628711721765103578702021239306242807889540598194;
    
    uint256 constant IC44x = 4065401509645223493564519295646622162889424291542843628586124041840918732175;
    uint256 constant IC44y = 18749220248870009381644873607926915815640947895710031826065953428082006402707;
    
    uint256 constant IC45x = 16240041607953109782959957335822768955189676448606333683654526899335322876684;
    uint256 constant IC45y = 1292785084053925555024149458942421854144629688585933781907591797428981712610;
    
    uint256 constant IC46x = 14178558232515842776155609632492430436518863355939704834362391025834932657616;
    uint256 constant IC46y = 13812238414952989792874107128498031763617806788574203337294260043931382522563;
    
    
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

        public_inputs[0] = 1877929696106340537431356748709024674978440512262073076129566312166640992621;
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