use web_sys::console;
use console_error_panic_hook;
use ark_bn254::{constraints::GVar, Bn254, Fr, G1Projective as G1};
use ark_grumpkin::{constraints::GVar as GVar2, Projective as G2};

use ark_groth16::Groth16;

use ark_ff::PrimeField;

use std::path::PathBuf;
use std::rc::Rc;
use std::time::Instant;

use folding_schemes::{
    utils::PathOrBin,
    commitment::{kzg::KZG, pedersen::Pedersen},
    folding::nova::{
        decider_eth::{prepare_calldata, Decider as DeciderEth},
        Nova, PreprocessorParam,
    },
    frontend::{circom::CircomFCircuit, FCircuit},
    transcript::poseidon::poseidon_canonical_config,
    Decider, Error, FoldingScheme
};
// use solidity_verifiers::{
//     utils::get_function_selector_for_nova_cyclefold_verifier,
//     verifiers::nova_cyclefold::get_decider_template_for_cyclefold_decider,
//     NovaCycleFoldVerifierKey,
// };

use crate::utils::tests::*;

// function to compute the next state of the folding via rust-native code (not Circom). Used to
// check the Circom values.
use tiny_keccak::{Hasher, Keccak};
pub fn rust_native_step<F: PrimeField>(
    _i: usize,
    z_i: Vec<F>,
    _external_inputs: Vec<F>,
) -> Result<Vec<F>, Error> {
    let b = f_vec_bits_to_bytes(z_i.to_vec());
    let mut h = Keccak::v256();
    h.update(&b);
    let mut z_i1 = [0u8; 32];
    h.finalize(&mut z_i1);
    bytes_to_f_vec_bits(z_i1.to_vec())
}

pub fn full_flow(r1cs_bytes: Vec<u8>, wasm_bytes: Vec<u8>) -> String {
    console_error_panic_hook::set_once();


    // set how many steps of folding we want to compute
    let n_steps = 5;

    // set the initial state
    let z_0_aux: Vec<u32> = vec![0_u32; 32 * 8];
    let z_0: Vec<Fr> = z_0_aux.iter().map(|v| Fr::from(*v)).collect::<Vec<Fr>>();

    let r1cs_bin = PathOrBin::from(r1cs_bytes);
    let wasm_bin = PathOrBin::from(wasm_bytes);

    // initialize the Circom circuit
    let f_circuit_params = (r1cs_bin, wasm_bin, 32 * 8, 0);
    let mut f_circuit = CircomFCircuit::<Fr>::new(f_circuit_params).unwrap();

    // Note (optional): for more speed, we can set a custom rust-native logic, which will be
    // used for the `step_native` method instead of extracting the values from the circom
    // witness:
    f_circuit.set_custom_step_native(Rc::new(rust_native_step));

    // return format!("hi");
    // everything above^ works

    // ----------------
    // Sanity check
    // check that the f_circuit produces valid R1CS constraints
    use ark_r1cs_std::alloc::AllocVar;
    use ark_r1cs_std::fields::fp::FpVar;
    use ark_r1cs_std::R1CSVar;
    use ark_relations::r1cs::ConstraintSystem;
    let cs = ConstraintSystem::<Fr>::new_ref();
    let z_0_var = Vec::<FpVar<Fr>>::new_witness(cs.clone(), || Ok(z_0.clone())).unwrap();

    match f_circuit.generate_step_constraints(cs.clone(), 1, z_0_var, vec![]) {
        Ok(z_1_var) => {
            return format!("hi");
        },
        Err(e) => {
            // THIS PRODUCES ERROR
            // hello_wasm.js:368 panicked at /home/czhang2718/.cargo/git/checkouts/circom-compat-69e71b86d9777e3c/18ca7f2/src/witness/circom.rs:158:33:
            // function getFrLen not found

            // Stack:

            // Error
            //     at imports.wbg.__wbg_new_abda76e883ba8a5f (http://localhost:8000/pkg/hello_wasm.js:352:21)
            //     at http://localhost:8000/pkg/hello_wasm_bg.wasm:wasm-function[490]:0x43613
            //     at http://localhost:8000/pkg/hello_wasm_bg.wasm:wasm-function[187]:0x38bae
            //     at http://localhost:8000/pkg/hello_wasm_bg.wasm:wasm-function[332]:0x3f180
            //     at http://localhost:8000/pkg/hello_wasm_bg.wasm:wasm-function[139]:0x2d22d
            //     at http://localhost:8000/pkg/hello_wasm_bg.wasm:wasm-function[53]:0x14939
            //     at run_keccak (http://localhost:8000/pkg/hello_wasm.js:226:10)
            //     at http://localhost:8000/:25:9
            web_sys::console::error_1(&format!("Error generating step constraints: {:?}", e).into());
            panic!("Failed to generate step constraints");
        },
    }
    let z_1_var = f_circuit
        .generate_step_constraints(cs.clone(), 1, z_0_var, vec![])
        .unwrap();
    
    // check z_1_var against the native z_1
    let z_1_native = f_circuit.step_native(1, z_0.clone(), vec![]).unwrap();
    assert_eq!(z_1_var.value().unwrap(), z_1_native);
    // check that the constraint system is satisfied
    assert!(cs.is_satisfied().unwrap());
    // ----------------

    // return "good"

    // define type aliases for the FoldingScheme (FS) and Decider (D), to avoid writting the
    // whole type each time
    pub type FS =
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
        FS,
    >;

    let poseidon_config = poseidon_canonical_config::<Fr>();
    let mut rng = rand::rngs::OsRng;

    // prepare the Nova prover & verifier params
    let nova_preprocess_params = PreprocessorParam::new(poseidon_config, f_circuit.clone());

    let start = Instant::now();
    let nova_params = FS::preprocess(&mut rng, &nova_preprocess_params).unwrap();

    

    // initialize the folding scheme engine, in our case we use Nova
    // let mut nova = FS::init(&nova_params, f_circuit.clone(), z_0.clone()).unwrap();

    // // run n steps of the folding iteration
    // let start_full = Instant::now();
    // for _ in 0..n_steps {
    //     let start = Instant::now();
    //     nova.prove_step(rng, vec![], None).unwrap();
    //     println!(
    //         "Nova::prove_step (keccak256 through Circom) {}: {:?}",
    //         nova.i,
    //         start.elapsed()
    //     );
    // }
    // println!(
    //     "Nova's all {} steps time: {:?}",
    //     n_steps,
    //     start_full.elapsed()
    // );
    // return format!(
    //     "Nova's all {} steps time: {:?}",
    //     n_steps,
    //     start_full.elapsed()
    // );

    // // perform the hash chain natively in rust (which uses a rust Keccak256 library)
    // let mut z_i_native = z_0.clone();
    // for i in 0..n_steps {
    //     z_i_native = rust_native_step(i, z_i_native, vec![]).unwrap();
    // }
    // // check that the value of the last folding state (nova.z_i) computed through folding, is
    // // equal to the natively computed hash using the rust_native_step method
    // assert_eq!(nova.z_i, z_i_native);

    // // ----------------
    // // Sanity check
    // // The following lines contain a sanity check that checks the IVC proof (before going into
    // // the zkSNARK proof)
    // let (running_instance, incoming_instance, cyclefold_instance) = nova.instances();
    // FS::verify(
    //     nova_params.1.clone(), // Nova's verifier params
    //     z_0,
    //     nova.z_i.clone(),
    //     nova.i,
    //     running_instance,
    //     incoming_instance,
    //     cyclefold_instance,
    // )
    // .unwrap();
    // // ----------------

    // // prepare the Decider prover & verifier params
    // let start = Instant::now();
    // let (decider_pp, decider_vp) = D::preprocess(&mut rng, &nova_params, nova.clone()).unwrap();
    // println!("Decider params generated: {:?}", start.elapsed());

    // let rng = rand::rngs::OsRng;
    // let start = Instant::now();
    // let proof = D::prove(rng, decider_pp, nova.clone()).unwrap();
    // println!("generated Decider proof: {:?}", start.elapsed());

    // let verified = D::verify(
    //     decider_vp.clone(),
    //     nova.i,
    //     nova.z_0.clone(),
    //     nova.z_i.clone(),
    //     &nova.U_i,
    //     &nova.u_i,
    //     &proof,
    // )
    // .unwrap();
    // assert!(verified);
    // println!("Decider proof verification: {}", verified);
}