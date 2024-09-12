// FROG FOLDING!

use wasm_bindgen::prelude::*;

#[wasm_bindgen]
extern {
    pub fn alert(s: &str);
}

use ark_serialize::{CanonicalDeserialize, CanonicalSerialize};
use ark_bn254::{constraints::GVar, Bn254, Fr, G1Projective as G1};

use ark_groth16::Groth16;
use ark_grumpkin::{constraints::GVar as GVar2, Projective as G2};

use num_bigint::BigInt;
use num_traits::Num;
use ark_ff::BigInteger256;

use std::path::PathBuf;

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

use std::fs;
use serde::Deserialize;
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

#[wasm_bindgen]
pub fn frog_nova(r1cs_bytes: Vec<u8>, wasm_bytes: Vec<u8>, frogs_js: JsValue) {

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


    println!("Start frog_nova");

    let frogs_str = frogs_js.as_string().unwrap(); // String


    // Deserialize JSON string into Vec<Frog>
    let frogs: Vec<Frog> = serde_json::from_str(&frogs_str).expect("Failed to deserialize JSON");
    
    fn str_to_fr(input_string: &str)-> Fr {
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

    let external_inputs: Vec<Vec<Fr>> = frogs.iter()
    .map(|frog| frog_to_fr_vector(frog))
    .collect();

    alert("external_inputs created");

    // initialize z_0 to [0,0,0] (to compare against any first [frogMessageHash2Small_fr, frogMessageHash2Big_fr])
    let z_0 = vec![Fr::from(0_u32), Fr::from(0_u32), Fr::from(0_u32)]; 

    // (r1cs_bytes, wasm_bytes, state_len, external_inputs_len)
    let f_circuit_params = (r1cs_bytes.into(), wasm_bytes.into(), 3, 22);
    let mut f_circuit = CircomFCircuit::<Fr>::new(f_circuit_params).unwrap();

    alert("created circuit!");

    

    // prepare the Nova prover & verifier params
    let nova_preprocess_params = PreprocessorParam::new(poseidon_config, f_circuit.clone());
    let nova_params = N::preprocess(&mut rng, &nova_preprocess_params).unwrap();

    alert("prepared nova prover and verifier params!");

    // initialize the folding scheme engine, in our case we use Nova
    let mut nova = N::init(&nova_params, f_circuit.clone(), z_0).unwrap();

    alert("initialized folding scheme!");

    // run n steps of the folding iteration
    for (i, external_inputs_at_step) in external_inputs.iter().enumerate() {
        nova.prove_step(rng, external_inputs_at_step.clone(), None)
            .unwrap();  
        alert(&format!("Nova::prove_step {}", i));
    }

    alert("finished folding!"); // works up to here in browser 8/23 12:17PM

    rng = rand::rngs::OsRng;

    alert("rng again");

    // let (decider_pp, decider_vp) = D::preprocess(&mut rng, &nova_params, nova.clone()).unwrap();
    decider_vp = VerifierParam::<
                    Projective,
                    KZG<'static, Bn254>,
                    <Groth16<Bn254> as SNARK<Fr>>::VerifyingKey,
                >::deserialize_compressed(&mut decider_vp_serialized.as_slice()).unwrap();
    decider_pp = PreprocessorParam::deserialize_compressed(&mut decider_pp_serialized.as_slice()).unwrap();

    alert("decider_pp and decider_vp deserialized");

    // decider proof generation
    let proof = D::prove(rng, decider_pp, nova.clone()).unwrap();
    alert("generated Decider proof");

    // decider proof verification
    let verified = D::verify(
        decider_vp.clone(),
        nova.i.clone(),
        nova.z_0.clone(),
        nova.z_i.clone(),
        &nova.U_i,
        &nova.u_i,
        &proof,
    )
    .unwrap();

    alert(&format!("Decider proof verified: {:?}", verified));

    // The rest of this test will serialize the data and deserialize it back, and use it to
    // verify the proof:

    // serialize the verifier_params, proof and public inputs
    let mut decider_vp_serialized = vec![];
    decider_vp
        .serialize_compressed(&mut decider_vp_serialized)
        .unwrap();

    alert(&format!("decider_vp_serialized: {:?}", decider_vp_serialized));
    web_sys::console::log_1(&format!("decider_vp_serialized: {:?}", decider_vp_serialized).into());

    let mut proof_serialized = vec![];
    proof.serialize_compressed(&mut proof_serialized).unwrap();

    alert(&format!("proof_serialized: {:?}", proof_serialized));
    web_sys::console::log_1(&format!("proof_serialized: {:?}", proof_serialized).into());

    // serialize the public inputs in a single packet
    let mut public_inputs_serialized = vec![];
    nova.i
        .serialize_compressed(&mut public_inputs_serialized)
        .unwrap();
    nova.z_0
        .serialize_compressed(&mut public_inputs_serialized)
        .unwrap();
    nova.z_i
        .serialize_compressed(&mut public_inputs_serialized)
        .unwrap();
    nova.U_i
        .serialize_compressed(&mut public_inputs_serialized)
        .unwrap();
    nova.u_i
        .serialize_compressed(&mut public_inputs_serialized)
        .unwrap();

    alert(&format!("public_inputs_serialized: {:?}", public_inputs_serialized));
    web_sys::console::log_1(&format!("public_inputs_serialized: {:?}", public_inputs_serialized).into());

    alert("🎉");
}