// FROG FOLDING!
/// hope this exists still


#![allow(non_snake_case)]
#![allow(non_camel_case_types)]
#![allow(clippy::upper_case_acronyms)]

// use ark_ff::MontBackend;
// /
// / This example performs the full flow:
// / - define the circuit to be folded
// / - fold the circuit with Nova+CycleFold's IVC
// / - generate a DeciderEthCircuit final proof
// / - generate the Solidity contract that verifies the proof
// / - verify the proof in the EVM
// /
// / 

// use ethereum_types::U256;

use std::fs;
// use std::io::Result;
use serde::Deserialize;
// use serde_json::Value;
use std::collections::HashMap;

use wasm_bindgen::prelude::*;

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
        Nova, PreprocessorParam, VerifierParam, CommittedInstance, Proof
    },
    frontend::{circom::CircomFCircuit, FCircuit},
    transcript::poseidon::poseidon_canonical_config,
    Decider, FoldingScheme,
};



// just do error handling on the javascript side
#[wasm_bindgen]
pub fn main(decider_vp_serialized: &[u8],
    proof_serialized: &[u8],
    public_inputs_serialized: &[u8]) {

    type N = Nova<
        Projective,
        GVar,
        Projective2,
        GVar2,
        CubicFCircuit<Fr>,
        KZG<'static, Bn254>,
        Pedersen<Projective2>,
        false,
    >;
    type D = Decider<
        Projective,
        GVar,
        Projective2,
        GVar2,
        CubicFCircuit<Fr>,
        KZG<'static, Bn254>,
        Pedersen<Projective2>,
        Groth16<Bn254>, // here we define the Snark to use in the decider
        N,              // here we define the FoldingScheme to use
    >;

    // deserialize back the verifier_params, proof and public inputs
    let decider_vp_deserialized =
    VerifierParam::<
        Projective,
        KZG<'static, Bn254>,
        <Groth16<Bn254> as SNARK<Fr>>::VerifyingKey,
    >::deserialize_compressed(&mut decider_vp_serialized.as_slice())
    .unwrap();
    let proof_deserialized =
        Proof::<Projective, KZG<'static, Bn254>, Groth16<Bn254>>::deserialize_compressed(
            &mut proof_serialized.as_slice(),
        )
        .unwrap();

    // deserialize the public inputs from the single packet 'public_inputs_serialized'
    let mut reader = public_inputs_serialized.as_slice();
    let i_deserialized = Fr::deserialize_compressed(&mut reader).unwrap();
    let z_0_deserialized = Vec::<Fr>::deserialize_compressed(&mut reader).unwrap();
    let z_i_deserialized = Vec::<Fr>::deserialize_compressed(&mut reader).unwrap();
    let U_i_deserialized =
        CommittedInstance::<Projective>::deserialize_compressed(&mut reader).unwrap();
    let u_i_deserialized =
        CommittedInstance::<Projective>::deserialize_compressed(&mut reader).unwrap();

    // decider proof verification using the deserialized data
    let verified = D::verify(
        decider_vp_deserialized,
        i_deserialized,
        z_0_deserialized,
        z_i_deserialized,
        &U_i_deserialized,
        &u_i_deserialized,
        &proof_deserialized,
    )
    .unwrap();
    assert!(verified);

    // println!("Decider proof verification: {}", verified);

    // println!("🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉");

}