// THIS FILE READs IN SERIALIZED PARAMS FROM BIN FILES AND USES THEM TO DO REST OF FOLDING
// tested proving/verifier works end to end!

use ark_ec::bn::BnConfig;
use ark_serialize::{CanonicalDeserialize, CanonicalSerialize};
use ark_bn254::{constraints::GVar, Bn254, Fr, G1Projective as G1};
use ark_groth16::{Groth16, VerifyingKey, ProvingKey};
use ark_grumpkin::{constraints::GVar as GVar2, Projective as G2};

use num_bigint::BigInt;
use num_traits::Num;
use ark_ff::{BigInteger256, MontBackend};

use std::path::PathBuf;
use std::time::Instant;

use folding_schemes::commitment::CommitmentScheme;
use folding_schemes::{
    commitment::{kzg::KZG, pedersen::Pedersen},
    folding::nova::{
        decider_eth::{prepare_calldata, Decider as DeciderEth, VerifierParam},
        Nova, PreprocessorParam,
        ProverParams, VerifierParams, IVCProof,
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
    let start_total = Instant::now();

    let nova_pp_serialized = read_binary_file("./serialized_outputs/uncompressed/nova_pp_output.bin");
    let nova_vp_serialized = read_binary_file("./serialized_outputs/uncompressed/nova_vp_output.bin");
    println!("{}", "succesfully read nova serialized params!");

    let ivc_proof_serialized = read_binary_file("./serialized_outputs/nova_ivc_proof.bin");
    println!("{}", "succesfully read serialized nova IVC_proof!");

    // initialize the Circom circuit (needed to deserialize verifier params)
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
    // pub type FS = dyn FoldingScheme<G1, G2, CircomFCircuit<Fr>>;

    // TRYING UNCHECKED SERIALIZATION -- it worked!
    
    // prepare the Decider prover & verifier params
    // let (decider_pp, decider_vp) = D::preprocess(&mut rng, &nova_params, nova.clone()).unwrap();
    let start = Instant::now();
        let nova_pp_deserialized = ProverParams::<
            G1,
            G2,
            KZG<'static, Bn254>,
            Pedersen<G2>,
            >::deserialize_uncompressed_unchecked(
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
                false,
            >::deserialize_with_mode::<GVar, GVar2, CircomFCircuit<Fr>, _>(
                &mut nova_vp_serialized.as_slice(),
                ark_serialize::Compress::No,
                ark_serialize::Validate::No,
                f_circuit_params,
                // (), // fcircuit_params
            )
            .unwrap();
        println!("deserialized nova_vp: {:?}", start.elapsed());

    println!("{}", "successfully deserialized all nova params!");

    let ivc_proof: IVCProof<G1, G2> = IVCProof::deserialize_compressed(ivc_proof_serialized.as_slice()).unwrap();

    println!("{}", "succesfully deserialized nova ivc proof");

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    let start = Instant::now();
        let nova_params = (nova_pp_deserialized, nova_vp_deserialized);
        println!("created nova_params: {:?}", start.elapsed());

    // let start = Instant::now();
    //     let mut nova = N::init(&nova_params, f_circuit.clone(), z_0).unwrap();
    //     println!("initialized nova from deserialized params: {:?}", start.elapsed());

    N::verify(nova_params.1.clone(), ivc_proof.clone()).unwrap();

}