// THIS FILE READs IN SERIALIZED PARAMS FROM BIN FILES AND USES THEM TO DO REST OF FOLDING
// tested proving/verifier works end to end!

use ark_serialize::{CanonicalDeserialize, CanonicalSerialize};
use ark_bn254::{constraints::GVar, Bn254, Fr, G1Projective as G1};
use ark_groth16::{Groth16, VerifyingKey, ProvingKey};
use ark_grumpkin::{constraints::GVar as GVar2, Projective as G2};

use num_bigint::BigInt;
use num_traits::Num;
use ark_ff::BigInteger256;

use std::path::PathBuf;
use std::time::Instant;

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
use std::fs::File;
use std::io::Read;

use serde::Deserialize;
use std::collections::HashMap;


// RNG: we'll need to use a deterministic seed on both proof and verification
// let's just set it to 0
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


// helper function to convert frog data into a vector of Fr elements to use within external_inputs
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

// helper function to read in values from files (e.g. frog inputs and serialized parameters)
fn read_binary_file(path: &str) -> Vec<u8> {
    let mut file = File::open(path).unwrap();
    // Create a buffer to hold the binary data
    let mut buffer = Vec::new();
    // Read the file's binary data into the buffer
    file.read_to_end(&mut buffer).unwrap();
    return buffer;
}

fn main() {

    let nova_pp_serialized = read_binary_file("./serialized_outputs/nova_pp_output.bin");
    let nova_vp_serialized = read_binary_file("./serialized_outputs/nova_vp_output.bin");
    let g16_vk_serialized = read_binary_file("./serialized_outputs/g16_vk_output.bin");
    let g16_pk_serialized = read_binary_file("./serialized_outputs/g16_pk_output.bin");

    println!("{}", "succesfully read serialized params!");

    let start_total = Instant::now();

    let start = Instant::now();
    // let file_path = "./src/frog_inputs (3).json";
    let file_path = "./src/frog_inputs (4).json";
    let contents = fs::read_to_string(file_path);
        let frogs: HashMap<String, Frog> = serde_json::from_str(&contents.unwrap()).unwrap();

        let mut external_inputs: Vec<Vec<Fr>> = Vec::new();
        let n = frogs.len();

        for i in 1..=n {
            let i_string = i.to_string();
            let frog = &frogs[&i_string];
            let frog_fr_vector = frog_to_fr_vector(&frog);
            external_inputs.push(frog_fr_vector);
        }
        println!("created external_inputs!: {:?}", start.elapsed());


    // initialize z_0 to [0,0,0] (to compare against any first [frogMessageHash2Small_fr, frogMessageHash2Big_fr])
    let z_0 = vec![Fr::from(0_u32), Fr::from(0_u32), Fr::from(0_u32)]; 

    // initialize the Circom circuit
    let r1cs_path = PathBuf::from(
        "./circuits/build/frogIVC.r1cs"
    );
    let wasm_path = PathBuf::from(
        "./circuits/build/frogIVC_js/frogIVC.wasm",
    );

    // (r1cs_bytes, wasm_bytes, state_len, external_inputs_len)
    let start = Instant::now();
        let f_circuit_params = (r1cs_path.into(), wasm_path.into(), 3, 22);
        let f_circuit = CircomFCircuit::<Fr>::new(f_circuit_params).unwrap();
        println!("created circuit!: {:?}", start.elapsed());

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
    // let mut rng: rand::rngs::OsRng = rand::rngs::OsRng;
    let mut rng = ChaCha20Rng::from_seed([0u8; 32]);

    // checked serialization
    // // prepare the Decider prover & verifier params
    // // let (decider_pp, decider_vp) = D::preprocess(&mut rng, &nova_params, nova.clone()).unwrap();
    // let start = Instant::now();
    //     let nova_pp_deserialized = ProverParams::<
    //         G1,
    //         G2,
    //         KZG<'static, Bn254>,
    //         Pedersen<G2>,
    //         >::deserialize_compressed(
    //             &mut nova_pp_serialized.as_slice()
    //         )
    //         .unwrap();
    //     println!("deserialized nova_pp: {:?}", start.elapsed());

    // let start = Instant::now();
    //     let nova_vp_deserialized = VerifierParams::<
    //             G1,
    //             G2,
    //             KZG<'static, Bn254>,
    //             Pedersen<G2>,
    //         >::deserialize_compressed(
    //             &mut nova_vp_serialized.as_slice()
    //         )
    //         .unwrap();
    //     println!("deserialized nova_vp: {:?}", start.elapsed());
    
    // let start = Instant::now();
    //     let g16_vk_deserialized: VerifyingKey<Bn254> = VerifyingKey::deserialize_compressed(&mut g16_vk_serialized.as_slice()).unwrap();
    //     println!("deserialized g16_vk: {:?}", start.elapsed());

    // let start = Instant::now();
    //     let g16_pk_deserialized: ProvingKey<Bn254> = ProvingKey::deserialize_compressed(&mut g16_pk_serialized.as_slice()).unwrap();
    //     println!("deserialized g16_pk: {:?}", start.elapsed());

    // println!("{}", "successfully serialized all params!");

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    // TRYING UNCHECKED SERIALIZATION
    
    // prepare the Decider prover & verifier params
    // let (decider_pp, decider_vp) = D::preprocess(&mut rng, &nova_params, nova.clone()).unwrap();
    let start = Instant::now();
        let nova_pp_deserialized = ProverParams::<
            G1,
            G2,
            KZG<'static, Bn254>,
            Pedersen<G2>,
            >::deserialize_compressed_unchecked(
                &mut nova_pp_serialized.as_slice()
            )
            .unwrap();
        println!("deserialized nova_pp: {:?}", start.elapsed());

    let start = Instant::now();
        let nova_vp_deserialized = VerifierParams::<
                G1,
                G2,
                KZG<'static, Bn254>,
                Pedersen<G2>,
            >::deserialize_compressed_unchecked(
                &mut nova_vp_serialized.as_slice()
            )
            .unwrap();
        println!("deserialized nova_vp: {:?}", start.elapsed());
    
    let start = Instant::now();
        let g16_vk_deserialized: VerifyingKey<Bn254> = VerifyingKey::deserialize_compressed_unchecked(&mut g16_vk_serialized.as_slice()).unwrap();
        println!("deserialized g16_vk: {:?}", start.elapsed());

    let start = Instant::now();
        let g16_pk_deserialized: ProvingKey<Bn254> = ProvingKey::deserialize_compressed_unchecked(&mut g16_pk_serialized.as_slice()).unwrap();
        println!("deserialized g16_pk: {:?}", start.elapsed());

    println!("{}", "successfully serialized all params!");

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    let start = Instant::now();
        let nova_params = (nova_pp_deserialized, nova_vp_deserialized);
        println!("created nova_params: {:?}", start.elapsed());

    let start = Instant::now();
        let mut nova = N::init(&nova_params, f_circuit.clone(), z_0).unwrap();
        println!("initialized nova from deserialized params: {:?}", start.elapsed());

    let start = Instant::now();
        let decider_pp = (g16_pk_deserialized, (nova_params.0).cs_pp);
        println!("generated decider_pp: {:?}", start.elapsed());

    let start = Instant::now();
        let pp_hash = (nova_params.1).pp_hash().unwrap();
        let decider_vp: VerifierParam<G1, 
                <KZG<'static, Bn254> as CommitmentScheme<G1>>::VerifierParams, 
                <Groth16<Bn254> as ark_snark::SNARK<Fr>>::VerifyingKey> = VerifierParam {
            pp_hash,
            snark_vp: g16_vk_deserialized,
            cs_vp: (nova_params.1).cs_vp,
        };
        // println!("generated decider_pp: {:?}", decider_pp); // print to check it's same as when running main.rs (to serialize params)
        println!("generated decider_vp: {:?}", start.elapsed()); 

    println!("{}", "prepared the Decider prover & verifier params!");

    // run n steps of the folding iteration
    for (i, external_inputs_at_step) in external_inputs.iter().enumerate() {
        let start = Instant::now();
        nova.prove_step(rng.clone(), external_inputs_at_step.clone(), None)
            .unwrap(); //////////////////////////////////////////////////////////////////////////////////////////
        println!("🐸 Nova::prove_step {}: {:?}", i, start.elapsed());
        // println!(
        //     "state at last step (after {} iterations): {:?}",
        //     i,
        //     nova.state()
        // )
    }
    println!("{}", "finished folding!");

    let start = Instant::now();
    let proof = D::prove(rng.clone(), decider_pp, nova.clone()).unwrap();
    // let proof = D::prove(rng.clone(), decider_pp.clone(), nova.clone()).unwrap();
    println!("generated decider proof!: {:?}", start.elapsed());

    let start = Instant::now();
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

    // SERIALIZE the verifier_params, proof and public inputs
    let start = Instant::now();
        let mut decider_vp_serialized = vec![];
        decider_vp
            .serialize_compressed(&mut decider_vp_serialized)
            .unwrap();
        // println!("decider_vp_serialized: {:?}", decider_vp_serialized);
        println!("decider_vp_serialized: {:?}", start.elapsed());

    
    let start = Instant::now();
        let mut proof_serialized = vec![];
        proof.serialize_compressed(&mut proof_serialized).unwrap();
        // println!("proof_serialized: {:?}", proof_serialized);
        println!("proof_serialized: {:?}", start.elapsed());

    // serialize the public inputs in a single packet
    let start = Instant::now();
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
        // println!("public_inputs_serialized: {:?}", public_inputs_serialized);
        println!("public_inputs_serialized: {:?}", start.elapsed());

    println!("whole thing took this long: {:?}", start_total.elapsed());
    println!("{}", "🎉🎉🎉🎉🎉🎉🎉🎉");

}