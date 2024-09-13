// FROG FOLDING!

use wasm_bindgen::prelude::*;

#[wasm_bindgen]
extern {
    pub fn alert(s: &str);
}

use ark_serialize::{CanonicalDeserialize, CanonicalSerialize};
use ark_bn254::{constraints::GVar, Bn254, Fr, G1Projective as G1};
use ark_groth16::{Groth16, VerifyingKey, ProvingKey};
use ark_grumpkin::{constraints::GVar as GVar2, Projective as G2};

use num_bigint::BigInt;
use num_traits::Num;
use ark_ff::BigInteger256;

use std::path::PathBuf;

use folding_schemes::commitment::CommitmentScheme;
use folding_schemes::{
    commitment::{kzg::KZG, pedersen::Pedersen},
    folding::nova::{
        decider_eth::{prepare_calldata, Decider as DeciderEth, VerifierParam},
        Nova, PreprocessorParam,
        ProverParams, VerifierParams,
    },
    frontend::{circom::CircomFCircuit, FCircuit},
    transcript::poseidon::poseidon_canonical_config,
    Decider, FoldingScheme,
};

use std::fs;
use serde::Deserialize;
use std::collections::HashMap;

// RNG: we'll need to use a deterministic seed on both proof and verification
// (because parameter preprocessing and prove/verify depend on it)
// let's just set seed to 0 for now
// need an rng that supports initializing from a seed ==> chacha20rng
// it also implements RngCore and CryptoRng traits (which are required by nova/decider) yay :)
use rand_chacha::ChaCha20Rng;
use rand::SeedableRng;


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
pub fn frog_nova(r1cs_bytes: Vec<u8>,
    wasm_bytes: Vec<u8>,
    frogs_js: JsValue,
    nova_pp_serialized: Vec<u8>,
    nova_vp_serialized: Vec<u8>,
    g16_vk_serialized: Vec<u8>,
    g16_pk_serialized: Vec<u8>) {

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

    // Decider<C1, GC1, C2, GC2, FC, CS1, CS2, S, FS> commented here for type references

    let poseidon_config = poseidon_canonical_config::<Fr>();
    // let mut rng = rand::rngs::OsRng;
    let mut rng = ChaCha20Rng::from_seed([0u8; 32]); // need to use deterministic rng because downloading parameters (generated from same rng + seed)

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

    // deserialize parameters
    let nova_pp_deserialized = ProverParams::<
        G1,
        G2,
        KZG<'static, Bn254>,
        Pedersen<G2>,
        >::deserialize_compressed(
            &mut nova_pp_serialized.as_slice()
        )
        .unwrap();

    alert("deserialized nova_pp");
    web_sys::console::log_1(&format!("nova_pp_deserialized: {:?}", nova_pp_deserialized).into());


    let nova_vp_deserialized = VerifierParams::<
            G1,
            G2,
            KZG<'static, Bn254>,
            Pedersen<G2>,
        >::deserialize_compressed(
            &mut nova_vp_serialized.as_slice()
        )
        .unwrap();

    alert("deserialized nova_vp");
    web_sys::console::log_1(&format!("nova_vp_deserialized: {:?}", nova_vp_deserialized).into());

    let g16_vk_deserialized: VerifyingKey<Bn254> = VerifyingKey::deserialize_compressed(&mut g16_vk_serialized.as_slice()).unwrap();
    alert("deserialized g16_vk");
    web_sys::console::log_1(&format!("g16_vk_deserialized: {:?}", g16_vk_deserialized).into());


    let g16_pk_deserialized: ProvingKey<Bn254> = ProvingKey::deserialize_compressed(&mut g16_pk_serialized.as_slice()).unwrap();
    alert("deserialized g16_pk"); // runs up to here as of 9/12 11:14 PM

            // let pp_hash = nova_vp.pp_hash();
            // let pp = (g16_pk, nova_pp.cs_pp);
            // let vp = (pp_hash, g16_vk, nova_vp.cs_vp);
            // Ok((pp, vp))

    let nova_params = (nova_pp_deserialized, nova_vp_deserialized);
    alert("created nova_params");
    web_sys::console::log_1(&format!("nova_params: {:?}", nova_params).into());

    let mut nova = N::init(&nova_params, f_circuit.clone(), z_0).unwrap();
    alert("initialized nova from the deserialized parameters");

    // TODO - find cleaner way to avoid ownership issues
    // (problem is functions expect certain types D: so it's not immediately &s everywhere)
    let decider_pp = (g16_pk_deserialized, (nova_params.0).cs_pp);
    alert("prepared decider_pp!");
    web_sys::console::log_1(&format!("decider_pp: {:?}", decider_pp).into());

    let pp_hash = (nova_params.1).pp_hash().unwrap();
    let decider_vp: VerifierParam<G1, 
            <KZG<'static, Bn254> as CommitmentScheme<G1>>::VerifierParams, 
            <Groth16<Bn254> as ark_snark::SNARK<Fr>>::VerifyingKey> = VerifierParam {
        pp_hash,
        snark_vp: g16_vk_deserialized,
        cs_vp: (nova_params.1).cs_vp,
    };

    // let (decider_pp, decider_vp) = D::preprocess(&mut rng, &nova_params, nova.clone()).unwrap();
    alert("prepared decider_vp!");
    web_sys::console::log_1(&format!("decider_vp: {:?}", decider_vp).into());

    // run n steps of the folding iteration
    for (i, external_inputs_at_step) in external_inputs.iter().enumerate() {
        nova.prove_step(rng.clone(), external_inputs_at_step.clone(), None)
            .unwrap();  
        alert(&format!("Nova::prove_step {}", i));
    }

    alert("finished folding!"); // works up to here in browser 8/23 12:17PM

    let proof = D::prove(rng.clone(), decider_pp, nova.clone()).unwrap();
    alert("generated decider proof!");

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

    alert("🎉🎉🎉🎉🎉🎉🎉🎉🎉 RAHHHHHH");
}