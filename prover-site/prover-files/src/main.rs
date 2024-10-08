// FROG FOLDING!

#![allow(non_snake_case)]
#![allow(non_camel_case_types)]
#![allow(clippy::upper_case_acronyms)]
// use ark_ff::MontBackend;
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

use ark_groth16::Groth16;
// use ark_groth16::{Groth16, Proof};
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

use std::fs;
// use std::io::Result;
use serde::Deserialize;
// use serde_json::Value;
use std::collections::HashMap;

#[derive(Debug, Deserialize)]
struct Frog {
    frogId: String,
    biome: String,
    rarity: String,
    temperament: String,
    jump: String,
    speed: String,
    intelligence: String,
    beauty: String,
    timestampSigned: String,
    ownerSemaphoreId: String,
    frogSignerPubkeyAx: String,
    frogSignerPubkeyAy: String,
    semaphoreIdentityTrapdoor: String,
    semaphoreIdentityNullifier: String,
    watermark: String,
    frogSignatureR8x: String,
    frogSignatureR8y: String,
    frogSignatureS: String,
    externalNullifier: String,
    reservedField1: String,
    reservedField2: String,
    reservedField3: String,
}

fn main() {

    println!("\nlet's 🐸 fold 🐸 some 🐸 frogs 🐸🐸🐸🐸🐸\n");

    let file_path = "./src/frog_inputs (4).json";
    let contents = fs::read_to_string(file_path);
    let frogs: HashMap<String, Frog> = serde_json::from_str(&contents.unwrap()).unwrap();

    // helper function to turn strings into Fr elements to feed into folding/circuits
    fn str_to_fr(input_string: &str)-> Fr {
        // let bigint: BigInt;
        // if (&input_string[0..2] == "0x") {
        //     bigint = BigInt::from_str_radix(input_string, 16).unwrap();
        // } else {
        //     bigint = BigInt::from_str_radix(input_string, 10).unwrap();
        // }
        let bigint: BigInt = BigInt::from_str_radix(input_string, 10).unwrap();
    
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

    fn frog_to_fr_vector(frog: &Frog) -> Vec<Fr> {
        return vec![
            str_to_fr(&frog.frogId),
            str_to_fr(&frog.timestampSigned),
            str_to_fr(&frog.ownerSemaphoreId),
            str_to_fr(&frog.frogSignerPubkeyAx),
            str_to_fr(&frog.frogSignerPubkeyAy),
            str_to_fr(&frog.semaphoreIdentityTrapdoor),
            str_to_fr(&frog.semaphoreIdentityNullifier),
            str_to_fr(&frog.watermark),
            str_to_fr(&frog.frogSignatureR8x),
            str_to_fr(&frog.frogSignatureR8y),
            str_to_fr(&frog.frogSignatureS),
            str_to_fr(&frog.externalNullifier),
            str_to_fr(&frog.biome),
            str_to_fr(&frog.rarity),
            str_to_fr(&frog.temperament),
            str_to_fr(&frog.jump),
            str_to_fr(&frog.speed),
            str_to_fr(&frog.intelligence),
            str_to_fr(&frog.beauty),
            str_to_fr(&frog.reservedField1),
            str_to_fr(&frog.reservedField2),
            str_to_fr(&frog.reservedField3),
        ];
    }

    let mut external_inputs: Vec<Vec<Fr>> = Vec::new();
    let n = frogs.len();

    for i in 1..=n {
        let i_string = i.to_string();
        let frog = &frogs[&i_string];
        let frog_fr_vector = frog_to_fr_vector(&frog);
        external_inputs.push(frog_fr_vector);
    }

    // println!("printing external_inputs...");
    // println!("{:?}", external_inputs);

    // set the initial state
    // initialize z_0 to [0,0,0] (to compare against any first [frogMessageHash2Small_fr, frogMessageHash2Big_fr])
    let z_0 = vec![Fr::from(0_u32), Fr::from(0_u32), Fr::from(0_u32)]; 

    // set the external inputs to be used at each step of the IVC
    // external_input is just two frogs, formatted correctly

    // initialize the Circom circuit
    let r1cs_path = PathBuf::from(
        "./circuits/build/frogIVC.r1cs"
    );
    let wasm_path = PathBuf::from(
        "./circuits/build/frogIVC_js/frogIVC.wasm",
    );

    // (r1cs_path, wasm_path, state_len, external_inputs_len)
    let f_circuit_params = (r1cs_path, wasm_path, 3, 22);
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
        println!("🐸 Nova::prove_step {}: {:?}", i, start.elapsed());
        println!(
            "state at last step (after {} iterations): {:?}",
            i,
            nova.state()
        )
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

    println!("🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉");
    println!("🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉");

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
    println!("storing nova-verifier.sol and the calldata into files");
    fs::write(
        "./src/nova_solidity_outputs/frogIVC_split-nova-verifier.sol",
        decider_solidity_code.clone(),
    )
    .unwrap();
    fs::write("./src/nova_solidity_outputs/frogIVC_split-solidity-calldata.calldata", calldata.clone()).unwrap();
    let s = solidity_verifiers::utils::get_formatted_calldata(calldata.clone());
    fs::write("./src/nova_solidity_outputs/frogIVC_split-solidity-calldata.inputs", s.join(",\n")).expect("");
}