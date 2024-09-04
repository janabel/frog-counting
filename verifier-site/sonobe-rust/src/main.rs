// FROG FOLDING!

#![allow(non_snake_case)]
#![allow(non_camel_case_types)]
#![allow(clippy::upper_case_acronyms)]
// use ark_bn254::Bn254;
use ark_crypto_primitives::sponge::Absorb;
use ark_ec::{AffineRepr, CurveGroup, Group};
use ark_ff::{BigInteger, PrimeField};
// use ark_groth16::Groth16;
use ark_r1cs_std::{groups::GroupOpsBounds, prelude::CurveVar, ToConstraintFieldGadget};
use ark_serialize::{CanonicalDeserialize, CanonicalSerialize};
use ark_snark::SNARK;
use ark_std::rand::{CryptoRng, RngCore};
use ark_std::{One, Zero};
use core::marker::PhantomData;
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
/// 
// use wasm_bindgen::prelude::wasm_bindgen;

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

use folding_schemes::folding::nova::CommittedInstance;
use folding_schemes::{
    commitment::{kzg::KZG, pedersen::Pedersen},
    folding::nova::{
        decider_eth::{prepare_calldata, Decider as DeciderEth, VerifierParam, Proof},
        Nova, PreprocessorParam,
    },
    frontend::{circom::CircomFCircuit, FCircuit},
    transcript::poseidon::poseidon_canonical_config,
    Decider, FoldingScheme,
};

use std::fs;
// use std::io::Result;
use serde::Deserialize;
// use serde_json::Value;
use std::collections::HashMap;

// #[wasm_bindgen]
pub fn verifyRust(decider_vp_serialized: Vec<u8>, proof_serialized: Vec<u8>, public_inputs_serialized: Vec<u8>) {

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

    // deserialize back the verifier_params, proof and public inputs
    let decider_vp_deserialized =
    VerifierParam::<
        G1,
        KZG<'static, Bn254>,
        <Groth16<Bn254> as SNARK<Fr>>::VerifyingKey,
    >::deserialize_compressed(&mut decider_vp_serialized.as_slice())
    .unwrap();
    let proof_deserialized =
        Proof::<G1, KZG<'static, Bn254>, Groth16<Bn254>>::deserialize_compressed(
            &mut proof_serialized.as_slice(),
        )
        .unwrap();

    // deserialize the public inputs from the single packet 'public_inputs_serialized'
    let mut reader = public_inputs_serialized.as_slice();
    let i_deserialized = Fr::deserialize_compressed(&mut reader).unwrap();
    let z_0_deserialized = Vec::<Fr>::deserialize_compressed(&mut reader).unwrap();
    let z_i_deserialized = Vec::<Fr>::deserialize_compressed(&mut reader).unwrap();
    let U_i_deserialized =
        CommittedInstance::<G1>::deserialize_compressed(&mut reader).unwrap();
    let u_i_deserialized =
        CommittedInstance::<G1>::deserialize_compressed(&mut reader).unwrap();

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

    println!("Decider proof verification: {}", verified);
    println!("🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉");

}