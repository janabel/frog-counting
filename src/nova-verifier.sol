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
            6143002743359140008391451861521142846732312181100750508275959836859053710401,
            13820262418585786202745795687502711037479629687717782857674230382002087029098
    ];
    uint256[2][2] G_2 = [
        [
            363602126053814348393634115791801943508056518792615388197432849077038125432,
            14223694074302010141196806169942303626830335741656064974752482714453220284770
        ],
        [
            17119315502810688489230950440029242646969870952242417181575826887577390108109,
            7169536340815832916761767673638698801909842660085889203072395688207068403244
        ]
    ];
    uint256[2][2] VK = [
        [
            18657204318986379579248080337494349169908650659429479644841747207381250383291,
            1860889620749646960275002503690084849555484947360670445032019327556913506777
        ],
        [
            18183339322158081215183302424156436911171375217295515482986063270905792166483,
            8225457208845021092188002012929459789273946150404676128007950675380780639320
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
    uint256 constant alphax  = 4385242460082556685503953306347607377432655666651449777367819925162255067988;
    uint256 constant alphay  = 15710405149754234746470406016469332772216341316746139205214449445574084442257;
    uint256 constant betax1  = 1821893088620769445970658666575857877106827863183457348344402446492292586559;
    uint256 constant betax2  = 11065556535396809411051125457942718514623467657707416000056640884130604778505;
    uint256 constant betay1  = 16024319861516994267703211812204628064681518635100607170456110313245294371856;
    uint256 constant betay2  = 6701047294143490888529252721887855398521878298389293013423411843711527125218;
    uint256 constant gammax1 = 5172143169574621717654040775963865086292382421821110447188757841708767489038;
    uint256 constant gammax2 = 11733152465451603512337731145665541864993293061686208878461650994629806786569;
    uint256 constant gammay1 = 17582325345723745515567520001216280115787615814793686246436783917350772698036;
    uint256 constant gammay2 = 21849965010360107683746044997197829233133376435096419952652818632617371306451;
    uint256 constant deltax1 = 4466458513606997337304765855181006272759564729187413525229175692931613747978;
    uint256 constant deltax2 = 12566273541592348756019160350021051177866420639550333891372982061511807320712;
    uint256 constant deltay1 = 1819189984521607288141798552405435630839582745956559264179402049444999301684;
    uint256 constant deltay2 = 4735675467097874883476356398165720705216177801072792298963280175805345085926;

    
    uint256 constant IC0x = 18964882009135905301959679726181388670537753913589099215795354967253524206778;
    uint256 constant IC0y = 18969334061737531011782329494181127326977451346147564172529894612402176534381;
    
    uint256 constant IC1x = 8804663526022207063906682237333070871879765805070905229526739188367945736799;
    uint256 constant IC1y = 6664335770329027914680040318205352184416055360956543925143616936186320918087;
    
    uint256 constant IC2x = 645449052105157610861862806677487547478052611422223781891659097161742330767;
    uint256 constant IC2y = 10300277632226244080745753654102288190499439074017144546903580093141624528151;
    
    uint256 constant IC3x = 20616681561049947502601704541232096857574188502910627786904186771535196840562;
    uint256 constant IC3y = 20302011693940848231059410735446429056694275412920919972204296583248972066936;
    
    uint256 constant IC4x = 846649990767659315259638692124665951506049634596413722287858563648266406569;
    uint256 constant IC4y = 2479494712045630114393723581667511577541082701908035631229329014610041815539;
    
    uint256 constant IC5x = 17841743327242844389366570199115708448143600432917571327243556508845149146089;
    uint256 constant IC5y = 4746415799178139107222144413552189697512816865214366232035880435585124807317;
    
    uint256 constant IC6x = 7028586479933892337394411302812466655490210633395307443436546031709545668576;
    uint256 constant IC6y = 2350383566414177873894258337009615062023261962037328518331567261246980390662;
    
    uint256 constant IC7x = 1797893083899621255594748533130613016323946789486212474182077670154190857827;
    uint256 constant IC7y = 11724797953506027812153545958574923136899471644856168307173020456427436983060;
    
    uint256 constant IC8x = 7694664716173307635907526072722742852086060381815869497487639350621386710299;
    uint256 constant IC8y = 10207025374033997675116654941065102750590545260265663749085234217133344565445;
    
    uint256 constant IC9x = 4171331521786726115989784255287659818188848414538068547006896078053005577745;
    uint256 constant IC9y = 4420810466683485513380438191451512512727997912210297985856687035222179043229;
    
    uint256 constant IC10x = 11141571334425561067646340305431367491925632775566852289736610968167581709751;
    uint256 constant IC10y = 3415673978343634820925721563563137982501465167550594109881578416612172818045;
    
    uint256 constant IC11x = 11274805059341334673181654333121843115817665391188638133444088034286869138591;
    uint256 constant IC11y = 21785796844247543965781791701285684968908295429939954566211960484962389723757;
    
    uint256 constant IC12x = 10719320699936088769935619005276769543909289281421538045765782687399795974556;
    uint256 constant IC12y = 11912607580814164062541242115679244027128302073045126323713566261544271621448;
    
    uint256 constant IC13x = 3605918689163877975506269148035179619458692982843897409201892044376668327327;
    uint256 constant IC13y = 5676307184768889001900049372704903974711591124406166942313389144786630488601;
    
    uint256 constant IC14x = 21417489892384046338421515504311504306279517772348796436698148019925959019682;
    uint256 constant IC14y = 1950125096031055362474504711509228215318375580787385455344495681105569915093;
    
    uint256 constant IC15x = 13146010384065988859852016072685519961887196695576249224591020240471392599223;
    uint256 constant IC15y = 17089702311309608146142829156481609189620749925500819638960669656844232934618;
    
    uint256 constant IC16x = 14252174486880392741175866693525898212186257502495953741079983903139298120521;
    uint256 constant IC16y = 14519707449572491915478084560985101416875147842450057780612550127573899188126;
    
    uint256 constant IC17x = 17497675502402465157159742978210208366208641011024292403680546937788923250624;
    uint256 constant IC17y = 2487085620375135216403472511078127688584427989545523987684772337306100360156;
    
    uint256 constant IC18x = 7230938784811650453191626085220155127161781755983931676176450467861953677862;
    uint256 constant IC18y = 17836464163725603651027125683618316864333597564473659471872668080047894943424;
    
    uint256 constant IC19x = 6056863864687304679019497658672552131476410369427282945620421131591821357748;
    uint256 constant IC19y = 16322940129288579834214970986956866902369567060952491128463614144220626586987;
    
    uint256 constant IC20x = 13931281507309645176508163815450696255322478668539403434741284690816704312313;
    uint256 constant IC20y = 20287119836368298869834469558263017531348319745561998068889329997313888441867;
    
    uint256 constant IC21x = 5557714230302864414772334934936203675593519063018490001569031574759120528451;
    uint256 constant IC21y = 11437498903505122099211130521228124621274411952007425073400995208231208988707;
    
    uint256 constant IC22x = 4206825858515165986867520857445954413863965482382459025536572098093594590834;
    uint256 constant IC22y = 20782212292817618740987517137483527720828132184856673584811468772371514023401;
    
    uint256 constant IC23x = 9083578391413173594876975448057413812037630689122014639113151285369878848795;
    uint256 constant IC23y = 8807285978922203821975480514704952883127058644399252088454222956742817828164;
    
    uint256 constant IC24x = 13879997472641738141172575430767035495375503839918292727623790671140610587626;
    uint256 constant IC24y = 17868366794762329703615558119713631194485527009557142795167654861765041823053;
    
    uint256 constant IC25x = 19320216621409600430478516286923159023751700589129018501152463354115854511624;
    uint256 constant IC25y = 3881964880801904430703512379703351982507638109968954406355210688484735010477;
    
    uint256 constant IC26x = 16643936773701400711156113644355869419615289193018197634323691458861458357569;
    uint256 constant IC26y = 14994398851757657548308324151285267903836288332378287215183720364834211795901;
    
    uint256 constant IC27x = 6283942241161062764830194320673939549820044940568499229458681868666379336700;
    uint256 constant IC27y = 18709776078734852694661103572790832620704580122661882543566794059312783251170;
    
    uint256 constant IC28x = 2865533057871343310283509539898841517740466218247409630097425407864099955053;
    uint256 constant IC28y = 9133078775341940461230835389491771017790047239559187734399411977263986625372;
    
    uint256 constant IC29x = 12682652585237661590479972488379594310730425480306571437254709596579551584706;
    uint256 constant IC29y = 12078540297377052724385704340414362393881002672335918016075279564075424683138;
    
    uint256 constant IC30x = 21695068463606479947438152850658305782782698136248703046241843971567321834578;
    uint256 constant IC30y = 15397892501384340754635012859376254347011353218651179831253289563008116527412;
    
    uint256 constant IC31x = 16742430937107429500595098298986122843280328425477391091223594730631150499070;
    uint256 constant IC31y = 19915548651179181754852844401938573217394822428072773082029635291768856946308;
    
    uint256 constant IC32x = 1652408580643533970667892272015819393975422758565436506033656012198239584152;
    uint256 constant IC32y = 14420979699587116895660502148917627603626249750486844986096355706420148670717;
    
    uint256 constant IC33x = 2962854075891817670944486829062202791361918740803843657672668058366249994744;
    uint256 constant IC33y = 17852515257572700190691659037791627843319690133083919805800473071636962653425;
    
    uint256 constant IC34x = 2342683865536794978093792103967670661950022001302551992286920322889845081694;
    uint256 constant IC34y = 17077179598114149536857195967284222148691645516584937226270816042408333265568;
    
    uint256 constant IC35x = 14129270679498245673095717382767321771757514781927845446196357783854798185461;
    uint256 constant IC35y = 4713405347543049520684285577294860318044809139249911966757948844709773414783;
    
    uint256 constant IC36x = 5557857922220949058470803086753035961015378309268856261802771131066017866497;
    uint256 constant IC36y = 19009788112723042733098829308653883031088517187144268690574383054804474623481;
    
    uint256 constant IC37x = 6374481577329416854741057011631864798134890251836623192270849115406276397750;
    uint256 constant IC37y = 14179981176038109674602018110667742882271520304179036824990640821527686211032;
    
    uint256 constant IC38x = 15512319816646308120106510080154306219005431418166211290460640206679862960074;
    uint256 constant IC38y = 3980838253709439345444560427520409271332263906301187710318897176524421119642;
    
    uint256 constant IC39x = 7220082476038732464877395853145058647574735634424629433350393358591138526385;
    uint256 constant IC39y = 20618737543635097501503900945733904170700702723278177211488576965445169489879;
    
    uint256 constant IC40x = 21068087821022878352739968908066429736956153242587832587835847556299261669150;
    uint256 constant IC40y = 1526653465705625548369619311355132515884822120003091928199953663844846705769;
    
    uint256 constant IC41x = 7167884963203655159161493226071062828485365506219720838903654514076359378880;
    uint256 constant IC41y = 6994999291649622938383759978908326568261510672079508196922888101006182764738;
    
    uint256 constant IC42x = 3562933924522096425213123634733690109392083151007139407033242451143480377695;
    uint256 constant IC42y = 15216577253542730338938976609987717491229622906900604661319081916911517324760;
    
    
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

        public_inputs[0] = 12781155279814841863178832271585968888936478684315622075665022339080397735490;
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