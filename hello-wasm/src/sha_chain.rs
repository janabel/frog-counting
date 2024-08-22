///
/// This example performs the full flow:
/// - define the circuit to be folded
/// - fold the circuit with Nova+CycleFold's IVC
/// - generate a DeciderEthCircuit final proof
/// - generate the Solidity contract that verifies the proof
/// - verify the proof in the EVM
///

#[cfg(test)]
mod tests {
    use ark_bn254::{constraints::GVar, Bn254, Fr, G1Projective as G1};
    use ark_grumpkin::{constraints::GVar as GVar2, Projective as G2};

    use ark_groth16::Groth16;

    use ark_ff::PrimeField;

    use std::time::Instant;

    use ark_crypto_primitives::crh::sha256::{constraints::Sha256Gadget, digest::Digest, Sha256};
    use ark_r1cs_std::fields::fp::FpVar;
    use ark_r1cs_std::{bits::uint8::UInt8, boolean::Boolean, ToBitsGadget, ToBytesGadget};
    use ark_relations::r1cs::{ConstraintSystemRef, SynthesisError};
    use std::marker::PhantomData;

    use folding_schemes::{
        commitment::{kzg::KZG, pedersen::Pedersen},
        folding::nova::{
            decider_eth::{prepare_calldata, Decider as DeciderEth},
            Nova, PreprocessorParam,
        },
        frontend::FCircuit,
        transcript::poseidon::poseidon_canonical_config,
        Decider, Error, FoldingScheme,
    };
    use solidity_verifiers::{
        utils::get_function_selector_for_nova_cyclefold_verifier,
        verifiers::nova_cyclefold::get_decider_template_for_cyclefold_decider,
        NovaCycleFoldVerifierKey,
    };

    use crate::utils::tests::*;

    /// Test circuit to be folded
    #[derive(Clone, Copy, Debug)]
    pub struct SHA256FoldStepCircuit<F: PrimeField, const HASHES_PER_STEP: usize> {
        _f: PhantomData<F>,
    }
    impl<F: PrimeField, const HASHES_PER_STEP: usize> FCircuit<F>
        for SHA256FoldStepCircuit<F, HASHES_PER_STEP>
    {
        type Params = ();
        fn new(_params: Self::Params) -> Result<Self, Error> {
            Ok(Self { _f: PhantomData })
        }
        fn state_len(&self) -> usize {
            32
        }
        fn external_inputs_len(&self) -> usize {
            0
        }
        // function to compute the next state of the folding via rust-native code (not Circom). Used to
        // check the Circom values.
        fn step_native(
            &self,
            _i: usize,
            z_i: Vec<F>,
            _external_inputs: Vec<F>,
        ) -> Result<Vec<F>, Error> {
            let mut b = f_vec_to_bytes(z_i.to_vec());

            for _ in 0..HASHES_PER_STEP {
                let mut sha256 = Sha256::default();
                sha256.update(b);
                b = sha256.finalize().to_vec();
            }

            bytes_to_f_vec(b.to_vec()) // z_{i+1}
        }
        fn generate_step_constraints(
            &self,
            _cs: ConstraintSystemRef<F>,
            _i: usize,
            z_i: Vec<FpVar<F>>,
            _external_inputs: Vec<FpVar<F>>,
        ) -> Result<Vec<FpVar<F>>, SynthesisError> {
            let mut b: Vec<UInt8<F>> = z_i
                .iter()
                .map(|f| UInt8::<F>::from_bits_le(&f.to_bits_le().unwrap()[..8]))
                .collect::<Vec<_>>();

            for _ in 0..HASHES_PER_STEP {
                let mut sha256_var = Sha256Gadget::default();
                sha256_var.update(&b).unwrap();
                b = sha256_var.finalize()?.to_bytes()?;
            }

            let z_i1: Vec<FpVar<F>> = b
                .iter()
                .map(|e| {
                    let bits = e.to_bits_le().unwrap();
                    Boolean::<F>::le_bits_to_fp_var(&bits).unwrap()
                })
                .collect();

            Ok(z_i1)
        }
    }

    #[test]
    fn full_flow() {
        // set how many steps of folding we want to compute
        const N_STEPS: usize = 100;
        const HASHES_PER_STEP: usize = 10;
        println!("running Nova folding scheme on SHA256FoldStepCircuit, with N_STEPS={}, HASHES_PER_STEP={}. Total hashes = {}", N_STEPS, HASHES_PER_STEP, N_STEPS* HASHES_PER_STEP);

        // set the initial state
        // let z_0_aux: Vec<u32> = vec![0_u32; 32 * 8];
        let z_0_aux: Vec<u8> = vec![0_u8; 32];
        let z_0: Vec<Fr> = z_0_aux.iter().map(|v| Fr::from(*v)).collect::<Vec<Fr>>();

        let f_circuit = SHA256FoldStepCircuit::<Fr, HASHES_PER_STEP>::new(()).unwrap();

        // ----------------
        // Sanity check
        // check that the f_circuit produces valid R1CS constraints
        use ark_r1cs_std::alloc::AllocVar;
        use ark_r1cs_std::fields::fp::FpVar;
        use ark_r1cs_std::R1CSVar;
        use ark_relations::r1cs::ConstraintSystem;
        let cs = ConstraintSystem::<Fr>::new_ref();
        let z_0_var = Vec::<FpVar<Fr>>::new_witness(cs.clone(), || Ok(z_0.clone())).unwrap();
        let z_1_var = f_circuit
            .generate_step_constraints(cs.clone(), 1, z_0_var, vec![])
            .unwrap();
        // check z_1_var against the native z_1
        let z_1_native = f_circuit.step_native(1, z_0.clone(), vec![]).unwrap();
        assert_eq!(z_1_var.value().unwrap(), z_1_native);
        // check that the constraint system is satisfied
        assert!(cs.is_satisfied().unwrap());
        println!(
            "number of constraints of a single instantiation of the SHA256FoldStepCircuit: {}",
            cs.num_constraints()
        );
        // ----------------

        // define type aliases for the FoldingScheme (FS) and Decider (D), to avoid writting the
        // whole type each time
        pub type FS = Nova<
            G1,
            GVar,
            G2,
            GVar2,
            SHA256FoldStepCircuit<Fr, HASHES_PER_STEP>,
            KZG<'static, Bn254>,
            Pedersen<G2>,
            false,
        >;
        pub type D = DeciderEth<
            G1,
            GVar,
            G2,
            GVar2,
            SHA256FoldStepCircuit<Fr, HASHES_PER_STEP>,
            KZG<'static, Bn254>,
            Pedersen<G2>,
            Groth16<Bn254>,
            FS,
        >;

        let poseidon_config = poseidon_canonical_config::<Fr>();
        let mut rng = rand::rngs::OsRng;

        // prepare the Nova prover & verifier params
        let nova_preprocess_params = PreprocessorParam::new(poseidon_config, f_circuit);
        let start = Instant::now();
        let nova_params = FS::preprocess(&mut rng, &nova_preprocess_params).unwrap();
        println!("Nova params generated: {:?}", start.elapsed());

        // initialize the folding scheme engine, in our case we use Nova
        let mut nova = FS::init(&nova_params, f_circuit, z_0.clone()).unwrap();

        // run n steps of the folding iteration
        let start_full = Instant::now();
        for _ in 0..N_STEPS {
            let start = Instant::now();
            nova.prove_step(rng, vec![], None).unwrap();
            println!(
                "Nova::prove_step (sha256) {}: {:?}",
                nova.i,
                start.elapsed()
            );
        }
        println!(
            "Nova's all {} steps time: {:?}",
            N_STEPS,
            start_full.elapsed()
        );

        // ----------------
        // Sanity check
        // The following lines contain a sanity check that checks the IVC proof (before going into
        // the zkSNARK proof)
        let (running_instance, incoming_instance, cyclefold_instance) = nova.instances();
        FS::verify(
            nova_params.1.clone(), // Nova's verifier params
            z_0,
            nova.z_i.clone(),
            nova.i,
            running_instance,
            incoming_instance,
            cyclefold_instance,
        )
        .unwrap();
        // ----------------

        // prepare the Decider prover & verifier params
        let start = Instant::now();
        let (decider_pp, decider_vp) = D::preprocess(&mut rng, &nova_params, nova.clone()).unwrap();
        println!("Decider params generated: {:?}", start.elapsed());

        let rng = rand::rngs::OsRng;
        let start = Instant::now();
        let proof = D::prove(rng, decider_pp, nova.clone()).unwrap();
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
        assert!(verified);
        println!("Decider proof verification: {}", verified);

        // generate the Solidity code that verifies this Decider final proof
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

        /*
         * Note: since we're proving the SHA256 (ie. 32 byte size, 256 bits), the number of inputs
         * is too big for the contract. In a real world use case we would convert the binary
         * representation into a couple of field elements which would be inputs of the Decider
         * circuit, and in-circuit we would obtain the binary representation to be used for the
         * final proof check.
         *
         * The following code is commented out for that reason.
        // verify the proof against the solidity code in the EVM
        use solidity_verifiers::evm::{compile_solidity, Evm};
        let nova_cyclefold_verifier_bytecode =
            compile_solidity(&decider_solidity_code, "NovaDecider");
        let mut evm = Evm::default();
        let verifier_address = evm.create(nova_cyclefold_verifier_bytecode);
        let (_, output) = evm.call(verifier_address, calldata.clone());
        assert_eq!(*output.last().unwrap(), 1);
         */

        // save smart contract and the calldata
        println!("storing nova-verifier.sol and the calldata into files");
        use std::fs;
        fs::create_dir_all("./solidity").unwrap();
        fs::write(
            "./solidity/nova-verifier.sol",
            decider_solidity_code.clone(),
        )
        .unwrap();
        fs::write("./solidity/solidity-calldata.calldata", calldata.clone()).unwrap();
        let s = solidity_verifiers::utils::get_formatted_calldata(calldata.clone());
        fs::write("./solidity/solidity-calldata.inputs", s.join(",\n")).expect("");
    }
}