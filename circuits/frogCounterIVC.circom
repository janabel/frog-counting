pragma circom 2.0.0;

include "./isZero.circom";

// IVC formatted frogCounter circuit
template IsZeroIVC () {
    signal input ivc_input[1];
    signal input external_inputs[22];
    signal output ivc_output[1];

    var frogId = external_inputs[0];
    var biome = external_inputs[1];
    var rarity = external_inputs[2];
    var temperament = external_inputs[3];
    var jump = external_inputs[4];
    var speed = external_inputs[5];
    var intelligence = external_inputs[6];
    var beauty = external_inputs[7];
    var timestampSigned = external_inputs[8];
    var ownerSemaphoreId = external_inputs[9];

    // reserved fields
    var reservedField1 = external_inputs[10];
    var reservedField2 = external_inputs[11];
    var reservedField3 = external_inputs[12];

    // Signer of the frog: EdDSA public key
    var frogSignerPubkeyAx = external_inputs[13];
    var frogSignerPubkeyAy = external_inputs[14];

    // Signature of the frog: EdDSA signature
    var frogSignatureR8x = external_inputs[15];
    var frogSignatureR8y = external_inputs[16];
    var frogSignatureS = external_inputs[17];

    // Owner's Semaphore identity, private
    var semaphoreIdentityNullifier = external_inputs[18];
    var semaphoreIdentityTrapdoor = external_inputs[19];

    // External nullifier, used to tie together nullifiers within a single category.
    var externalNullifier = external_inputs[20];

    // Watermark allows prover to tie a proof to a challenge. It's unconstrained,
    // but included in the proof.
    var watermark = external_inputs[21];

    signal frogMessageHash <== Poseidon(13)([
        frogId,
        biome,
        rarity,
        temperament,
        jump,
        speed,
        intelligence,
        beauty,
        timestampSigned,
        ownerSemaphoreId,
        reservedField1,
        reservedField2,
        reservedField3
    ]);

    // Verify frog signature
    EdDSAPoseidonVerifier()(
        1,
        frogSignerPubkeyAx,
        frogSignerPubkeyAy,
        frogSignatureS,
        frogSignatureR8x,
        frogSignatureR8y,
        frogMessageHash
    );

    // Verify semaphore private identity matches the frog owner semaphore ID.
    signal semaphoreSecret <== Poseidon(2)([
        semaphoreIdentityNullifier,
        semaphoreIdentityTrapdoor
    ]);
    signal semaphoreIdentityCommitment <== Poseidon(1)([semaphoreSecret]);
    ownerSemaphoreId === semaphoreIdentityCommitment;

    // Calculate nullifier
    // signal output nullifierHash <== Poseidon(2)([externalNullifier, semaphoreIdentityNullifier]);

    // Dummy constraint on watermark to make sure it can't be compiled out.
    signal watermarkSquared <== watermark * watermark;

    ivc_output[0] <== ivc_input[0] + 1;
}

component main {public [ivc_input]} = IsZeroIVC();