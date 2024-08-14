// FROG FOLDING!

#![allow(non_snake_case)]
#![allow(non_camel_case_types)]
#![allow(clippy::upper_case_acronyms)]
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
    // set the initial state
    // initialize z_0 to 0 because it's a counter of how many 0s we have in external inputs
    // TO CHANGE
    let z_0 = vec![Fr::from(0_u32)]; 

    // set the external inputs to be used at each step of the IVC, it has length of 10 since this
    // is the number of steps that we will do
    // dummy external_input is just two frogs, formatted correctly (pkeys etc split into 2 u128 numbers each)
    // TO CHANGE
    
    let external_inputs = vec![
        vec![
        Fr::from(10u128),
        Fr::from(1723063971239u128),
        Fr::from(242540964306827918772044435538431719290u128),
        Fr::from(29281978767745550479479093098799635563u128),
        Fr::from(225754184667065099589268658398655020523u128),
        Fr::from(20064288421318982316939866241040515168u128),
        Fr::from(26243575505223386772563604788533682133u128),
        Fr::from(56070134347504961625256726916577453093u128),
        Fr::from(278797269441584481571747637135243878456u128),
        Fr::from(396847725509931452686287725923691323u128),
        Fr::from(8643358369179125308001081676912813933u128),
        Fr::from(1053993233930236514092689643248672076u128),
        Fr::from(2718u128),
        Fr::from(100104813512449048013016113837251321772u128),
        Fr::from(4356236049734175528556901829447135766u128),
        Fr::from(114475550550734564822383888683126183373u128),
        Fr::from(63016137138959701704038793347940342363u128),
        Fr::from(183240394593624311792083557354088055018u128),
        Fr::from(4088536058698458794210132237957472488u128),
        Fr::from(86344438408772883716058491394134982113u128),
        Fr::from(31331087239638548611211754232824005u128),
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
        Fr::from(10u128),
        Fr::from(1723063971239u128),
        Fr::from(242540964306827918772044435538431719290u128),
        Fr::from(29281978767745550479479093098799635563u128),
        Fr::from(225754184667065099589268658398655020523u128),
        Fr::from(20064288421318982316939866241040515168u128),
        Fr::from(26243575505223386772563604788533682133u128),
        Fr::from(56070134347504961625256726916577453093u128),
        Fr::from(278797269441584481571747637135243878456u128),
        Fr::from(396847725509931452686287725923691323u128),
        Fr::from(8643358369179125308001081676912813933u128),
        Fr::from(1053993233930236514092689643248672076u128),
        Fr::from(2718u128),
        Fr::from(100104813512449048013016113837251321772u128),
        Fr::from(4356236049734175528556901829447135766u128),
        Fr::from(114475550550734564822383888683126183373u128),
        Fr::from(63016137138959701704038793347940342363u128),
        Fr::from(183240394593624311792083557354088055018u128),
        Fr::from(4088536058698458794210132237957472488u128),
        Fr::from(86344438408772883716058491394134982113u128),
        Fr::from(31331087239638548611211754232824005u128),
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
    ]
    ];

    // initialize the Circom circuit
    let r1cs_path = PathBuf::from(
        "./circuits/build/frogIVC_split.r1cs"
    );
    let wasm_path = PathBuf::from(
        "./circuits/build/frogIVC_split_js/frogIVC_split.wasm",
    );

    // (r1cs_path, wasm_path, state_len, external_inputs_len)
    // TO CHANGE
    let f_circuit_params = (r1cs_path, wasm_path, 1, 31);
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
            .unwrap();
        println!("Nova::prove_step {}: {:?}", i, start.elapsed());
    }

    println!("{}", "finished folding!");

    let start = Instant::now();
    let proof = D::prove(rng, decider_pp, nova.clone()).unwrap();

    
// fn debug_proof(proof: &Proof<Bn254>) {
//     format!("{:?}", proof.snark_proof)
// }

//     println!("proof: {}", debug_proof(&proof));
    // println!("proof: {:?}", proof);
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