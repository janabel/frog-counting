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
            10008201749300104593616376294135240306166511623148215815951604704506823094862,
            4090539198268342417752545536324530602593605437212294138200216331599510968643
    ];
    uint256[2][2] G_2 = [
        [
            21008577959834601629319874282857319361407888242529599345254744466973219072504,
            2966883966685049603498634793182530699932131111606905465040241697964133418669
        ],
        [
            7827374478865077892216736119563063101736674029179508571512420966026015587922,
            9808393864597836953123522318777934493628835913585055446118127317675503245758
        ]
    ];
    uint256[2][2] VK = [
        [
            15151992311148435192812114332488145430070600773273966754299036226249364934967,
            2405914372929429759967205102047701712841758253425443542984366309900990905613
        ],
        [
            19412364364189412853234568618415208694786314958221425048618543263293390709204,
            5588763521963733495660514293810601649765146265253168067181715845029501393061
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
    uint256 constant alphax  = 3194161596574357420493962923813067799995585839379731444706116048299048088904;
    uint256 constant alphay  = 10663087626998878403884767102945893689258277313848191049438853377161594783666;
    uint256 constant betax1  = 16148079670066937231115980413933075690992362552196849712401251920194473639124;
    uint256 constant betax2  = 8027663663210132541351155950778721940295882809710349386144950407657360241277;
    uint256 constant betay1  = 9986522407804388346522152925730494581567780709264784196126601549518819723002;
    uint256 constant betay2  = 6357510221070369137000831811609621524054402699254210581449661358883738124678;
    uint256 constant gammax1 = 12081342417094261731217458298391658890173738963797007674224649146534300760920;
    uint256 constant gammax2 = 13254917811314660311710082421160955048951226749475217355429471651030418343836;
    uint256 constant gammay1 = 3602769064886077054534464243392628554343968416229884738149332631371534357085;
    uint256 constant gammay2 = 7795756334505049406035858863972816162292968343400522202234704290772951517887;
    uint256 constant deltax1 = 8400604204593282783704606026076720592712885979268152363098020307548739680406;
    uint256 constant deltax2 = 6156275156844967509376702556390167143866473089465313465075989779982200389890;
    uint256 constant deltay1 = 3523340554547104908985324290092844379860027931687216086813940967936376648539;
    uint256 constant deltay2 = 13136023935268506656572989580967835500881077061284121200644059227664106701688;

    
    uint256 constant IC0x = 13559964000841018866740462064187489101778178833511881106263439071562674008389;
    uint256 constant IC0y = 602467200448841026925607688662744812119426716313456500490796776820672135347;
    
    uint256 constant IC1x = 2551889561295862355705987538406831648469016072747342121198403201466212986024;
    uint256 constant IC1y = 14025775779247002480401142012041810708569505283503470304105784221729962978182;
    
    uint256 constant IC2x = 5234564504430149115447144752566473256424437761617475494280114512152763510937;
    uint256 constant IC2y = 490620075362134344208849109175106335425242426129825735805121974492311097615;
    
    uint256 constant IC3x = 11228711036656581154333748755351939360060467102094979629664054179604045209130;
    uint256 constant IC3y = 18365885361298296611080398375366811061733764211090048918145337974308325805339;
    
    uint256 constant IC4x = 7336716322040586131093124964808069338659696241396038864997059155446941216498;
    uint256 constant IC4y = 7473099000592902701049742830053079116529508391662936331152914643856250036926;
    
    uint256 constant IC5x = 1517868703837471849117509655483070687389711655441040000956819245603885307318;
    uint256 constant IC5y = 10246575492994873870579999633274489623752542390162330789790690597853829990854;
    
    uint256 constant IC6x = 12818683312069505637202814407858205783045579636019681663687156657284450574891;
    uint256 constant IC6y = 10352511060897094969357148121001924132905062813783375172462344761723514282199;
    
    uint256 constant IC7x = 1910495356188004176278243589790680049278738159289954716671315800792452669560;
    uint256 constant IC7y = 8211941374428743897809290489124226025035088978150802210793149269719022909412;
    
    uint256 constant IC8x = 21703480224875947584813728498819166714807052761229445379659444875738871096978;
    uint256 constant IC8y = 14141885086562348985165366586115890142466483151705536291383707647024980659954;
    
    uint256 constant IC9x = 18738745794483733933303131839768099795126043842497342519068092424946273187973;
    uint256 constant IC9y = 7517802232514743151434575261597782521608981927255171017934112524045665327372;
    
    uint256 constant IC10x = 4282841407978712710964468795550024332037300090061316561345496979402717930551;
    uint256 constant IC10y = 21374325848551910172019432548986042934100737512610304198260582649801644390506;
    
    uint256 constant IC11x = 11232968859299958169098329024012846444063610432101817409314438805038192797016;
    uint256 constant IC11y = 10836448973531259537757172112512329074875930503703686796289784438917357314258;
    
    uint256 constant IC12x = 6852690236614686540959434439305616314926248988875188615403895744080571970760;
    uint256 constant IC12y = 1407298353629275890880743960898892584484633977216100758363868525561232608387;
    
    uint256 constant IC13x = 3702328760299538179425244271298800762298735862925004091500090211075919516562;
    uint256 constant IC13y = 15741905243544572216133717783811447367802897051065321585801658848747647079372;
    
    uint256 constant IC14x = 18138165998049531221968788421537825550338677190978021699486798415107552212193;
    uint256 constant IC14y = 21237605822432690355566856132408364629549346118941434037887493344772236590749;
    
    uint256 constant IC15x = 19056359178414819139523522882053430278970446301834583832123517167778935895095;
    uint256 constant IC15y = 1708987741167460210756415805103678253055004870343802099999656186640099938584;
    
    uint256 constant IC16x = 21071163142107926000381387534441006725111956436990540208015528992901653041156;
    uint256 constant IC16y = 11046641924479434805665245945381397149466845463228134380532216535397242886825;
    
    uint256 constant IC17x = 7163440289773076716628833664251428857650538075648741609063298456200041479532;
    uint256 constant IC17y = 9044410443775486461526310096191779540499799963688052275659395713212505297920;
    
    uint256 constant IC18x = 19721276772089661096426892143372772221109512742057987692503243015266958498548;
    uint256 constant IC18y = 18000314455453296305042612035386619525799690542838576498852630528229102439166;
    
    uint256 constant IC19x = 16059193590279653032563606562662496328201518876273578289329991459856280361777;
    uint256 constant IC19y = 3639409772841997251276720622092091114312874700360172784295445047746637881755;
    
    uint256 constant IC20x = 20237870893988761420385881601176712703403012854440582948878805743405157731718;
    uint256 constant IC20y = 4902914109567124280086783344464166168432373490163202676737996890148063390592;
    
    uint256 constant IC21x = 5772144346622139673474591015169758849671461933150296258447976860761713121877;
    uint256 constant IC21y = 3340349501858884090044105166980849750958115120846297454437467286727977511154;
    
    uint256 constant IC22x = 18529953961891578595234739121223199024251868452735501091047808786570685521180;
    uint256 constant IC22y = 17804090143866745210820495080077825796248141699006530936310426210093348477826;
    
    uint256 constant IC23x = 20319906679612437259491645635497477334938739466250242314393831663174715617446;
    uint256 constant IC23y = 20417679513679150036746590212243500942262869034990415869773052752329083944319;
    
    uint256 constant IC24x = 9452490577426102146295696452859760645839115596910668895469779609693638078672;
    uint256 constant IC24y = 7689481978099853684910147365466242708937905842915688513745157568931897770973;
    
    uint256 constant IC25x = 10093358942961510228086764031954928321652359609450725337768260041487181807486;
    uint256 constant IC25y = 12738307859401480855780497307972216509287286171495348631900652861769637842396;
    
    uint256 constant IC26x = 14759908943892439787295268979136270988839537098291584496249854771719274442921;
    uint256 constant IC26y = 10453156639489409954819538715746007769790108500762507097868865988234272723681;
    
    uint256 constant IC27x = 20623104232148453635930647286955689148449154697949687833815915093297091473401;
    uint256 constant IC27y = 14592908051008497187295671031683809332368500362043770753683789043751067611793;
    
    uint256 constant IC28x = 14291929551140870812466960453495406349168618915940865505314460563422417090875;
    uint256 constant IC28y = 21209919502481951447287562924450789661873775133161195401116714822328981648721;
    
    uint256 constant IC29x = 3838337341756732122532901550271156716140989447839935921057188301937395369783;
    uint256 constant IC29y = 7444334555848311582512235496182146934487732499136739546972556349386506208510;
    
    uint256 constant IC30x = 16019973507734726297212947871620827184142304812579195066102612938698900684461;
    uint256 constant IC30y = 6781123493070669362827967286734750983000150039249252216418080817284012421960;
    
    uint256 constant IC31x = 14095208896466101424107580767108285755547816151367554091716814788795938148298;
    uint256 constant IC31y = 1600266471819161414997101455984675060371498310993665234209221963525119992726;
    
    uint256 constant IC32x = 1424430971171845840501062500144493409020983920535708197594681721429416486776;
    uint256 constant IC32y = 6025149435644564673720072411516919483360332569442136875500669726538554171154;
    
    uint256 constant IC33x = 17206550911724798166402975333580856792866431957183661221618319932373011511997;
    uint256 constant IC33y = 18165564987726045553032198450687715906115669659874300608495370636974988067598;
    
    uint256 constant IC34x = 18010231320542906978045170561152033222360787389002012392476571295179117275831;
    uint256 constant IC34y = 18618652260597030481619086219326477833173599622152700225973607519307593581274;
    
    uint256 constant IC35x = 12453457382896647183588340786848303541973000281562067146218080273126978963589;
    uint256 constant IC35y = 14008844373370264862067755281074260695870709340463433900233760764484155884587;
    
    uint256 constant IC36x = 15370484847482299453172465375325956511830311840801371435110354852118431634919;
    uint256 constant IC36y = 21283291360662155020232235152696773989154496575090314213176888371485946231680;
    
    uint256 constant IC37x = 15143239299521338047892057016029367475015230433049920552637628876391359898317;
    uint256 constant IC37y = 10874641857455550525251910988153460743256476490921956819854272451656940947496;
    
    uint256 constant IC38x = 1045690221664067812218718280301903660710200171352840572858573638412634430812;
    uint256 constant IC38y = 15760910915847813595019121842613147325155213108234305092750028151442722597360;
    
    uint256 constant IC39x = 13710674160329456279622873727976955624259692860031739262440274151479491445239;
    uint256 constant IC39y = 21407993373512335120910854295292343416826308430594764280173904070921699269817;
    
    uint256 constant IC40x = 10911659187433773859735484558536168668982881101815029182675231340498868394005;
    uint256 constant IC40y = 8445275822712926846232381880335829100580875463811177506547046609348226467865;
    
    uint256 constant IC41x = 5082047777530527318055333624545844074607996651620081074953905782246664035558;
    uint256 constant IC41y = 18283110839837022703110973691156372356059702017738013843657261804096675015375;
    
    uint256 constant IC42x = 3265858424805722433124961597767356502170777644625398208266235523178807450477;
    uint256 constant IC42y = 20473040503178763511753984925873982474094803925201678583825834033140554583156;
    
    uint256 constant IC43x = 10406305092534970711115206039048577824488304277665724706358016980740011519120;
    uint256 constant IC43y = 17481232190346118359673784676111087584419295000486877582230440796681421072479;
    
    uint256 constant IC44x = 17486383659769922921497469947269906526901793793503964552475610963607026827040;
    uint256 constant IC44y = 15494901952467788919124807346970043356654744897406815382890774896542890603913;
    
    
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

        public_inputs[0] = 5788627266409604705260692172285612380649967154134733690715463093927932214667;
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