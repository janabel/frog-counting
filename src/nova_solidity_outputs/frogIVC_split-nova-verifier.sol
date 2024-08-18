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
            5360417029682083299110582129644831319566644434045244292968076375211306205581,
            8348759414041832608279458022950272876897744635589604479536416273807106833988
    ];
    uint256[2][2] G_2 = [
        [
            21353506932593057349255521177428220559683927200877188213688434493403149041713,
            7605503230893087873747765910334092784720094150661377112673703089277001784920
        ],
        [
            6819317862466876296497211094764422201878421267448139374416922718404624268214,
            11862646580779095456603594062545804169050436444401671036104249359268250041395
        ]
    ];
    uint256[2][2] VK = [
        [
            13832388855479220124060302154146646561996353752062378273347797275417892403894,
            17354094595855744475293703162395617956654034344491562632110413010556611420199
        ],
        [
            18030231195791881899857133286952541464995241076297140117356572481596139378322,
            2661584957983511074841209685763521529888115986504881477084762360955503304604
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
    uint256 constant alphax  = 16332999413414953129706174064958528650242609865567545462870595454266884971999;
    uint256 constant alphay  = 4947584964762427910136890044302338257541175106913391120871743151435958385020;
    uint256 constant betax1  = 20314660259780111656246059927516004829977244419625706022229477949414951269396;
    uint256 constant betax2  = 589523378107064078844026170827093367316610315147807758185467116582817818312;
    uint256 constant betay1  = 682395459402264167189340819674199079574048314933033705153720509871941715465;
    uint256 constant betay2  = 2400975330462321487296996542563104867924290956431335728170736111794211925913;
    uint256 constant gammax1 = 19468458582405455874977590695106048287008248266147250206073067324265529460401;
    uint256 constant gammax2 = 8908869454200704762103693357729689049305103313413017736713135121766900844789;
    uint256 constant gammay1 = 14827637569202383721433581804088281507148593920461718594377267216081015795631;
    uint256 constant gammay2 = 4697452898277891097885500962188661725279751828803109986513491216699810913598;
    uint256 constant deltax1 = 9954911760865258125805850553523350491282305017924453493279392106998370959176;
    uint256 constant deltax2 = 18022503754659427847123413209255400283877704405726779150175337596833233188206;
    uint256 constant deltay1 = 19515547432880579992321359273686734217237002662459814332191441469217754147912;
    uint256 constant deltay2 = 17524272672803781891187856953989988932712625425161375442842936114793308263692;

    
    uint256 constant IC0x = 12114206560890327222374421191298494009166735825863048302030091132996450273343;
    uint256 constant IC0y = 12811059531973308766854987549615528023662090971611709504221431177448844596236;
    
    uint256 constant IC1x = 2689723569227283149307491141285183696997949818021342695959255855842788028814;
    uint256 constant IC1y = 741905821743883116247066394760302045548115609343954534373607576312766022291;
    
    uint256 constant IC2x = 1022867872339424426216013242384725349419865761354124333066753211566682476742;
    uint256 constant IC2y = 9257590081623145359114481615579637548863345523676579398817246831038535454529;
    
    uint256 constant IC3x = 165274892972348350680444030080872454543642112645082489251193002832036769521;
    uint256 constant IC3y = 20078793693767908527258384574755618141411424577548652015627244088069234833332;
    
    uint256 constant IC4x = 2841936585087640046320816678505794061503691336997503646780936122128686837795;
    uint256 constant IC4y = 11324483828442280874492390871661726923050342739809815013098581381100485915186;
    
    uint256 constant IC5x = 13822024121827696695861204820347190820091571748485733249051262112536557020811;
    uint256 constant IC5y = 19134136923816846517031103551739030517114949077292982249112407834146497679884;
    
    uint256 constant IC6x = 7930480290141587046768428053446455796826630049548515563715787288428747876979;
    uint256 constant IC6y = 13833291049606681825711465488396526033800269355798305749996902846038955770370;
    
    uint256 constant IC7x = 10540030731734619297757596447919866205399723714603089208898694382467886067966;
    uint256 constant IC7y = 640428948562429447131244672694451294755195094364476647713460153955870683451;
    
    uint256 constant IC8x = 2815337682600283846662859314140960772333384459790330912799178375530327047842;
    uint256 constant IC8y = 7686992273532368988197781512338662044301025192301948055720106862289867022983;
    
    uint256 constant IC9x = 11924278782680526964160738546469977944622320447187528098169633759463076420996;
    uint256 constant IC9y = 4028740434901093542408043792182089019396133373095822452165142515954684676885;
    
    uint256 constant IC10x = 10063001821211077579579076057226677279229608430996805459777900773512653895430;
    uint256 constant IC10y = 3827173973896768963698534845686900695918851128961706363027712054266070180691;
    
    uint256 constant IC11x = 9183845728830774509606373494262752716070000658991001242199999052471631945355;
    uint256 constant IC11y = 8584110051171371232313124048860830525019170003912690831353147997538990594160;
    
    uint256 constant IC12x = 5384227513152941315656266321541304418890291586858195916825993080673860866230;
    uint256 constant IC12y = 753359775196884379482118132268892329253759285461108009857517790443236304160;
    
    uint256 constant IC13x = 6460363685664077783384474187956113709259142398468874153558227951788612344299;
    uint256 constant IC13y = 12266332022477096089193168355560739963419218196338215311290209322402990579889;
    
    uint256 constant IC14x = 10123585562555757220216906843681792668572047095176353669969401959811761609027;
    uint256 constant IC14y = 11141822277455700205297654136294562017874982018171521025739557379521227465499;
    
    uint256 constant IC15x = 15929365217195911627198370146056414639574218935911871083584621586463455360917;
    uint256 constant IC15y = 8842920086702394682252998327555112430614689180312628691646974543964546791666;
    
    uint256 constant IC16x = 12607051102901484897201628064392467604533855323308248093529862172881010435532;
    uint256 constant IC16y = 6947288971570106198170471600201208420405416752170289745978664439255527728497;
    
    uint256 constant IC17x = 12282887305475743423085232902191939391684964113713409349558865143074233147975;
    uint256 constant IC17y = 17053851457638464098818124909692826041507571690641455998378143279471455843353;
    
    uint256 constant IC18x = 6028239087417272297594718597402835724388896843816083643886896256495412324393;
    uint256 constant IC18y = 10156841212949972687011372171353803241570998821270660024580532564020592145408;
    
    uint256 constant IC19x = 2011841860932484017507274541460721538432617335097441547940413862830895891098;
    uint256 constant IC19y = 6016124223941668196004897917052286995149716753199236886341601448755138192638;
    
    uint256 constant IC20x = 9355686300835469381707552327632434802899777854926510058980309592537735976754;
    uint256 constant IC20y = 16343159089076217936264723726622648772962069978233406052412913198008671535899;
    
    uint256 constant IC21x = 17625749566931001515139248209302961902820558478940465015896488588285911368653;
    uint256 constant IC21y = 18072433566519075571898402515317819591217573075833421406914844989122075426491;
    
    uint256 constant IC22x = 618768489539156140173807938794069790494967695405993959824799304973922370075;
    uint256 constant IC22y = 19497015645853666545633651470470727641739924442707711053287208157814454442781;
    
    uint256 constant IC23x = 7773135946168551038266242168198207319125264061335502778588888445182437789008;
    uint256 constant IC23y = 15688203758754370511513570234823235454133802699219128786873380801044601497169;
    
    uint256 constant IC24x = 915754326817894808710903701668232745989977625097978173418051363278976779689;
    uint256 constant IC24y = 8338632017624200653767242140277694860514035847394015485775247215642452177360;
    
    uint256 constant IC25x = 14983175556782935483631773136302470481265919485371747203240819217086423938889;
    uint256 constant IC25y = 14093266030544220507665453233984598521259809512289292237148780753848156749119;
    
    uint256 constant IC26x = 6654461086927720238436347600280861807378062640456829654632484212040108559296;
    uint256 constant IC26y = 15027273069225928969190829461924975348461503345202140989796068468989191559939;
    
    uint256 constant IC27x = 7735073013251440870434110944708423623124317536514056795671875533685591422028;
    uint256 constant IC27y = 15551513260263070476500036142792246702571122046252010734132182498069072122633;
    
    uint256 constant IC28x = 17180607922506628064785378596227958730502291838334909839829385249494153143055;
    uint256 constant IC28y = 1881363136293020445339806865631649345015752874605007013756938188373389610242;
    
    uint256 constant IC29x = 15686954590401577021241746232875248435574488392406562083817764451475509256783;
    uint256 constant IC29y = 8198965312636098514366077332579695186808743916481697841195471878202590567106;
    
    uint256 constant IC30x = 9443247869065268210463159918214413344559500754970012827462491514617272344700;
    uint256 constant IC30y = 3096766878912330447454548390267484896516941708874294563328567881695965766977;
    
    uint256 constant IC31x = 8799123220820413787751874969162364624331605651540298862760076181860414970985;
    uint256 constant IC31y = 15645546885818920620117618057108483743728687677576858640348594291372150560347;
    
    uint256 constant IC32x = 9714309270553544883022021696310798230504050031654410336634478005705454921619;
    uint256 constant IC32y = 2533137922327455492959077522501844844122079862361806203195773714547890048100;
    
    uint256 constant IC33x = 2590604861921106019877307945639627994518445466955761818713142423089789122356;
    uint256 constant IC33y = 1834780176774258922938495111844003542339808565818816667662585695963840381029;
    
    uint256 constant IC34x = 8906294205073383150895888127688046353022539247058755659306431939719727066091;
    uint256 constant IC34y = 5018791201320738508472450901522721164618101355230137700875582492290733425317;
    
    uint256 constant IC35x = 20155084438611788087594611082869927383981835666116878973757068393230301378976;
    uint256 constant IC35y = 1052362319027411797736072011272481036993865019836166225431217084949881597903;
    
    uint256 constant IC36x = 8124895777000950380797471300343096708320043631423562792080585016358883575221;
    uint256 constant IC36y = 7167612910757921688287135911986283533313547872554572358328823585399172190314;
    
    uint256 constant IC37x = 17188045278142833882815385804980394181133210074942366467107394139311019985270;
    uint256 constant IC37y = 4028973417683589454970142532735278476662220720033468828881712991225200352593;
    
    uint256 constant IC38x = 17358062643603994324558918887136198923928208851268166198394419662916184031322;
    uint256 constant IC38y = 17275122068535191123186648858649319853881459489658161543320464722736558498890;
    
    uint256 constant IC39x = 2171580371280487519723124126765268944660414227725320548909298328618977911076;
    uint256 constant IC39y = 1596290287532107607004419800336784305343782197557005751440832782572184461402;
    
    uint256 constant IC40x = 16699312990117963163809602427469021432132266563082362952809590205565070671581;
    uint256 constant IC40y = 529591807759296447332187791482085372844139075480498453559721223761951938050;
    
    uint256 constant IC41x = 11071132365215365195242839777734522076502996694547824244195001204369436649040;
    uint256 constant IC41y = 16123596633502923681090883262658886552009435355276360906369825912731389387475;
    
    uint256 constant IC42x = 7285434746052109715592725479376940283970447705201319368269633004689361412422;
    uint256 constant IC42y = 11848032341326522771222781838666500750682103568210585413803326196715217266522;
    
    uint256 constant IC43x = 7802279578199893700742201064619568244470389898371382921806674713282886120869;
    uint256 constant IC43y = 8207469001592340484043753220218745541009166586924953951476691855129505637875;
    
    uint256 constant IC44x = 9692264058274823736177319402851272339028300954885344780603267149825560634794;
    uint256 constant IC44y = 6799348270747439876172858260064593704925948398672414758654717353240949217484;
    
    
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

        public_inputs[0] = 16699469766266814375791179748122446253814534655134644619553316817778233982287;
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