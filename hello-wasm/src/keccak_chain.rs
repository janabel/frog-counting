use web_sys::console;
use wasm_bindgen::prelude::*;
use console_error_panic_hook;
use ark_bn254::{constraints::GVar, Bn254, Fr, G1Projective as G1};
use ark_grumpkin::{constraints::GVar as GVar2, Projective as G2};

use ark_groth16::Groth16;

use ark_ff::PrimeField;

use std::path::PathBuf;
use std::rc::Rc;

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

#[wasm_bindgen]
extern {
    pub fn alert(s: &str);
}

pub fn full_flow(r1cs_bytes: Vec<u8>, wasm_bytes: Vec<u8>) -> String {
    console_error_panic_hook::set_once();


    // set how many steps of folding we want to compute
    let n_steps = 2;

    // set the initial state
    let z_0_aux: Vec<u32> = vec![0_u32; 32 * 8];
    let z_0: Vec<Fr> = z_0_aux.iter().map(|v| Fr::from(*v)).collect::<Vec<Fr>>();

    // let r1cs_bin = PathOrBin::from(r1cs_bytes);
    // let wasm_bin = PathOrBin::from(wasm_bytes);

    // initialize the Circom circuit
    let f_circuit_params = (r1cs_bytes.into(), wasm_bytes.into(), 32 * 8, 0);
    let mut f_circuit = CircomFCircuit::<Fr>::new(f_circuit_params).unwrap();

    // Note (optional): for more speed, we can set a custom rust-native logic, which will be
    // used for the `step_native` method instead of extracting the values from the circom
    // witness:
    f_circuit.set_custom_step_native(Rc::new(rust_native_step));

    // return format!("hi");
    alert("step native");
    // everything above^ works

    
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

    alert("rng");

    // prepare the Nova prover & verifier params
    let nova_preprocess_params = PreprocessorParam::new(poseidon_config, f_circuit.clone());

    alert("nova_preprocess_params");

    let nova_params = FS::preprocess(&mut rng, &nova_preprocess_params).unwrap();
    alert("nova params");
    

    // initialize the folding scheme engine, in our case we use Nova
    let mut nova = FS::init(&nova_params, f_circuit.clone(), z_0.clone()).unwrap();

    // return format!("hi");

    // run n steps of the folding iteration
    for _ in 0..n_steps {
        nova.prove_step(rng, vec![], None).unwrap();
        alert(format!("Nova::prove_step {}", i));
    }

    // prepare the Decider prover & verifier params
    let (decider_pp, decider_vp) = D::preprocess(&mut rng, &nova_params, nova.clone()).unwrap();

    alert("D preprocess");

    let rng = rand::rngs::OsRng;
    let proof = D::prove(rng, decider_pp, nova.clone()).unwrap();

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
    assert!(verified);
    alert(format!("Decider proof verification: {}", verified));

    let public_input = D::get_public_input(
        decider_vp.clone(),
        nova.i,
        nova.z_0.clone(),
        nova.z_i.clone(),
        &nova.U_i,
        &nova.u_i,
        &proof,
    )
    .unwrap();
    alert("DONE");
    alert(&format!("{:?}", public_input).into());
    return format!("hi");
}