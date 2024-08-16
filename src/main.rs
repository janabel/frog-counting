// FROG FOLDING!

#![allow(non_snake_case)]
#![allow(non_camel_case_types)]
#![allow(clippy::upper_case_acronyms)]
use ark_ff::MontBackend;
///
/// This example performs the full flow:
/// - define the circuit to be folded
/// - fold the circuit with Nova+CycleFold's IVC
/// - generate a DeciderEthCircuit final proof
/// - generate the Solidity contract that verifies the proof
/// - verify the proof in the EVM
///
/// 

// use ethereum_types::U256;
use ark_bn254::{constraints::GVar, Bn254, Fr, G1Projective as G1};

use ark_groth16::{Groth16, Proof};
use ark_grumpkin::{constraints::GVar as GVar2, Projective as G2};

use num_bigint::BigInt;
use num_traits::Num;
use ark_ff::BigInteger256;

use std::path::PathBuf;
use std::time::Instant;

use folding_schemes::{
    commitment::{kzg::KZG, pedersen::Pedersen},
    folding::nova::{
        decider_eth::{prepare_calldata, Decider as DeciderEth},
        Nova, PreprocessorParam,
    },
    frontend::{circom::CircomFCircuit, FCircuit},
    transcript::poseidon::poseidon_canonical_config,
    Decider, FoldingScheme,
};
use solidity_verifiers::{
    evm::{compile_solidity, Evm},
    utils::get_function_selector_for_nova_cyclefold_verifier,
    verifiers::nova_cyclefold::get_decider_template_for_cyclefold_decider,
    NovaCycleFoldVerifierKey,
};

fn main() {

    // helper function to turn strings into Fr elements to feed into folding/circuits
    fn str_to_fr(input_string: &str)-> Fr {
        let bigint = BigInt::from_str_radix(input_string, 10).unwrap();
    
        let bigint_bytes = bigint.to_bytes_be().1;
        let mut bytes_32 = vec![0_u8; 32];
        bytes_32[(32 - bigint_bytes.len())..].copy_from_slice(&bigint_bytes);
    
        let big_integer = BigInteger256::new([
            u64::from_be_bytes(bytes_32[24..32].try_into().unwrap()),
            u64::from_be_bytes(bytes_32[16..24].try_into().unwrap()),
            u64::from_be_bytes(bytes_32[8..16].try_into().unwrap()),
            u64::from_be_bytes(bytes_32[0..8].try_into().unwrap()),
        ]);
    
        return Fr::from(big_integer);
    }



    // // frogMessageHash2_str is smaller, so put frog2 first and into z_0.
    // let frogMessageHash1_str = "13345530209821331975430602286579617572336268754766287259267125426531538163144"; // real frog
    // let frogMessageHash1_fr = str_to_fr(frogMessageHash1_str);
    // let frogMessageHash2_str = "19922957967242918696262285668014865019771324803111546006992398360310387592243";


    // set the initial state
    // initialize z_0 to [0,0] (to compare against any first [frogMessageHash2Small_fr, frogMessageHash2Big_fr])
    // TO CHANGE
    let z_0 = vec![Fr::from(0_u32), Fr::from(0_u32)]; 

    // set the external inputs to be used at each step of the IVC
    // external_input is just two frogs, formatted correctly
    // TO CHANGE


    // {
    //     "beauty": 6,
    //     "biome": 3,
    //     "externalNullifier": "10661416524110617647338817740993999665252234336167220367090184441007783393",
    //     "frogId": 26,
    //     "frogSignatureR8x": "3905193423010470989125634343912498114238974029402349774171177533113727872021",
    //     "frogSignatureR8y": "4220667839388476583517614235006410826454621394498244403361240346004021155209",
    //     "frogSignatureS": "2166162042551067351421606700226595766359806346872972800506681888202929856816",
    //     "frogSignerPubkeyAx": "6827523554590803092735941342538027861463307969735104848636744652918854385131",
    //     "frogSignerPubkeyAy": "19079678029343997910757768128548387074703138451525650455405633694648878915541",
    //     "intelligence": 6,
    //     "jump": 6,
    //     "ownerSemaphoreId": "21711510168635182051334357427785411794318044815986410056285364391413272857225",
    //     "rarity": 1,
    //     "reservedField1": "0",
    //     "reservedField2": "0",
    //     "reservedField3": "0",
    //     "semaphoreIdentityNullifier": "46501085880889723880043204259130159126257178560019589221443961884550616786",
    //     "semaphoreIdentityTrapdoor": "19203180509052113016252601264864235852564023528134367070099013180198396222",
    //     "speed": 4,
    //     "temperament": 10,
    //     "timestampSigned": 1723064403633,
    //     "watermark": "2718"
    //   }

    let frog_2_ownerSemaphoreId = str_to_fr("21711510168635182051334357427785411794318044815986410056285364391413272857225");
    let frog_2_frogSignerPubkeyAx = str_to_fr("6827523554590803092735941342538027861463307969735104848636744652918854385131");
    let frog_2_frogSignerPubkeyAy = str_to_fr("19079678029343997910757768128548387074703138451525650455405633694648878915541");
    let frog_2_semaphoreIdentityTrapdoor = str_to_fr("19203180509052113016252601264864235852564023528134367070099013180198396222");
    let frog_2_semaphoreIdentityNullifier = str_to_fr("46501085880889723880043204259130159126257178560019589221443961884550616786");
    let frog_2_frogSignatureR8x = str_to_fr("3905193423010470989125634343912498114238974029402349774171177533113727872021");
    let frog_2_frogSignatureR8y = str_to_fr("4220667839388476583517614235006410826454621394498244403361240346004021155209");
    let frog_2_frogSignatureS = str_to_fr("2166162042551067351421606700226595766359806346872972800506681888202929856816");
    let frog_2_externalNullifier = str_to_fr("10661416524110617647338817740993999665252234336167220367090184441007783393");

    // get frog attributes as Fr elements
    let frog_1_ownerSemaphoreId = str_to_fr("9964141043217120936664326897183667118469716023855732146334024524079553329018");
    let frog_1_frogSignerPubkeyAx = str_to_fr("6827523554590803092735941342538027861463307969735104848636744652918854385131");
    let frog_1_frogSignerPubkeyAy = str_to_fr("19079678029343997910757768128548387074703138451525650455405633694648878915541");
    let frog_1_semaphoreIdentityTrapdoor = str_to_fr("135040283343710365777958365424694852760089427911973547434460426204380274744");
    let frog_1_semaphoreIdentityNullifier = str_to_fr("358655312360435269311557940631516683613039221013826685666349061378483316589");
    let frog_1_frogSignatureR8x = str_to_fr("1482350313869864254042595459421095897218687816166241224483874238825079857068");
    let frog_1_frogSignatureR8y = str_to_fr("21443280299859662584655395271110089155773803041593918291203552153143944893901");
    let frog_1_frogSignatureS = str_to_fr("1391256727295516554759691112683783404841502861038527717248540264088174477546");
    let frog_1_externalNullifier = str_to_fr("10661416524110617647338817740993999665252234336167220367090184441007783393");
    
    // frog2, then frog 1 in order (based on hash sizes)
    let external_inputs = vec![

    vec![
        Fr::from(10u128),
        Fr::from(1723063971239u128),
        frog_1_ownerSemaphoreId,
        frog_1_frogSignerPubkeyAx,
        frog_1_frogSignerPubkeyAy,
        frog_1_semaphoreIdentityTrapdoor,
        frog_1_semaphoreIdentityNullifier,
        Fr::from(2718u128),
        frog_1_frogSignatureR8x,
        frog_1_frogSignatureR8y,
        frog_1_frogSignatureS,
        frog_1_externalNullifier,
        Fr::from(3u128),
        Fr::from(1u128),
        Fr::from(11u128),
        Fr::from(1u128),
        Fr::from(1u128),
        Fr::from(0u128),
        Fr::from(3u128),
        Fr::from(0u128),
        Fr::from(0u128),
        Fr::from(0u128),
    ],
        vec![
        Fr::from(26u8), // frogId
        Fr::from(1723064403633u128), // timestampSigned
        frog_2_ownerSemaphoreId, // ownerSemaphoreId
        frog_2_frogSignerPubkeyAx, // frogSignerPubkeyAx
        frog_2_frogSignerPubkeyAy, // frogSignerPubkeyAy
        frog_2_semaphoreIdentityTrapdoor, // semaphoreIdentityTrapdoor
        frog_2_semaphoreIdentityNullifier, // semaphoreIdentityNullifier
        Fr::from(2718u128), // watermark
        frog_2_frogSignatureR8x, // frogSignatureR8x
        frog_2_frogSignatureR8y, // frogSignatureR8y
        frog_2_frogSignatureS, // frogSignatureS
        frog_2_externalNullifier, // externalNullifier
        Fr::from(3u8), // biome
        Fr::from(1u8), // rarity
        Fr::from(10u8), // temperament
        Fr::from(6u8), // jump
        Fr::from(4u8), // speed
        Fr::from(6u8), // intelligence
        Fr::from(6u8), // beauty
        Fr::from(0u8), // reservedField1
        Fr::from(0u8), // reservedField2
        Fr::from(0u8), // reservedField3
    ],
    ];

    // initialize the Circom circuit
    let r1cs_path = PathBuf::from(
        "./circuits/build/frogIVC.r1cs"
    );
    let wasm_path = PathBuf::from(
        "./circuits/build/frogIVC_js/frogIVC.wasm",
    );

    // (r1cs_path, wasm_path, state_len, external_inputs_len)
    // TO CHANGE
    let f_circuit_params = (r1cs_path, wasm_path, 2, 22);
    let f_circuit = CircomFCircuit::<Fr>::new(f_circuit_params).unwrap();

    println!("{}", "created circuit!");

    pub type N =
        Nova<G1, GVar, G2, GVar2, CircomFCircuit<Fr>, KZG<'static, Bn254>, Pedersen<G2>, false>;
    pub type D = DeciderEth<
        G1,
        GVar,
        G2,
        GVar2,
        CircomFCircuit<Fr>,
        KZG<'static, Bn254>,
        Pedersen<G2>,
        Groth16<Bn254>,
        N,
    >;

    let poseidon_config = poseidon_canonical_config::<Fr>();
    let mut rng = rand::rngs::OsRng;

    // prepare the Nova prover & verifier params
    let nova_preprocess_params = PreprocessorParam::new(poseidon_config, f_circuit.clone());
    let nova_params = N::preprocess(&mut rng, &nova_preprocess_params).unwrap();

    println!("{}", "prepared nova prover and verifier params!");

    // initialize the folding scheme engine, in our case we use Nova
    let mut nova = N::init(&nova_params, f_circuit.clone(), z_0).unwrap();

    println!("{}", "initialized folding scheme!");

    // prepare the Decider prover & verifier params
    let (decider_pp, decider_vp) = D::preprocess(&mut rng, &nova_params, nova.clone()).unwrap();
    println!("{}", "prepared decider prover & verifier params!");

    // run n steps of the folding iteration
    for (i, external_inputs_at_step) in external_inputs.iter().enumerate() {
        let start = Instant::now();
        nova.prove_step(rng, external_inputs_at_step.clone(), None)
            .unwrap(); //////////////////////////////////////////////////////////////////////////////////////////
        println!("Nova::prove_step {}: {:?}", i, start.elapsed());
    }

    println!("{}", "finished folding!");

    let start = Instant::now();
    let proof = D::prove(rng, decider_pp, nova.clone()).unwrap();
    // println!("{:?}", proof);

    println!("generated Decider proof: {:?}", start.elapsed());

    let verified = D::verify(
        decider_vp.clone(),
        nova.i,
        nova.z_0.clone(),
        nova.z_i.clone(),
        &nova.U_i,
        &nova.u_i,
        &proof,
    )
    .unwrap();
    println!("unwrapped verify: {:?}", start.elapsed());

    assert!(verified);
    println!("Decider proof verification: {}", verified);

    // Now, let's generate the Solidity code that verifies this Decider final proof
    let function_selector =
        get_function_selector_for_nova_cyclefold_verifier(nova.z_0.len() * 2 + 1);

    let calldata: Vec<u8> = prepare_calldata(
        function_selector,
        nova.i,
        nova.z_0,
        nova.z_i,
        &nova.U_i,
        &nova.u_i,
        proof,
    )
    .unwrap();

    // prepare the setup params for the solidity verifier
    let nova_cyclefold_vk = NovaCycleFoldVerifierKey::from((decider_vp, f_circuit.state_len()));

    // generate the solidity code
    let decider_solidity_code = get_decider_template_for_cyclefold_decider(nova_cyclefold_vk);

    // verify the proof against the solidity code in the EVM
    let nova_cyclefold_verifier_bytecode = compile_solidity(&decider_solidity_code, "NovaDecider");
    let mut evm = Evm::default();
    let verifier_address = evm.create(nova_cyclefold_verifier_bytecode);
    let (_, output) = evm.call(verifier_address, calldata.clone());
    assert_eq!(*output.last().unwrap(), 1);

    // save smart contract and the calldata
    // TO CHANGE (names of paths)
    println!("storing nova-verifier.sol and the calldata into files");
    use std::fs;
    fs::write(
        "./src/frogIVC_split-nova-verifier.sol",
        decider_solidity_code.clone(),
    )
    .unwrap();
    fs::write("./src/frogIVC_split-solidity-calldata.calldata", calldata.clone()).unwrap();
    let s = solidity_verifiers::utils::get_formatted_calldata(calldata.clone());
    fs::write("./src/frogIVC_split-solidity-calldata.inputs", s.join(",\n")).expect("");
}