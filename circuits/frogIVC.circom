pragma circom 2.1.5;

include "./frog.circom";

// IVC formatted frogCounter circuit
template frogIVC () {
    signal input ivc_input[1];
    signal input external_inputs[22];
    // signal output nullifierHash[1];
    signal output ivc_output[1];

    component frogVerify = EdDSAFrogPCD();
    frogVerify.frogId <== external_inputs[0];
    frogVerify.timestampSigned <== external_inputs[1];
    frogVerify.ownerSemaphoreId <== external_inputs[2];
    frogVerify.frogSignerPubkeyAx <== external_inputs[3];
    frogVerify.frogSignerPubkeyAy <== external_inputs[4];
    frogVerify.semaphoreIdentityTrapdoor <== external_inputs[5];
    frogVerify.semaphoreIdentityNullifier <== external_inputs[6];
    frogVerify.watermark <== external_inputs[7];
    frogVerify.frogSignatureR8x <== external_inputs[8];
    frogVerify.frogSignatureR8y <== external_inputs[9];
    frogVerify.frogSignatureS <== external_inputs[10];
    frogVerify.externalNullifier <== external_inputs[11];
    frogVerify.biome <== external_inputs[12];
    frogVerify.rarity <== external_inputs[13];
    frogVerify.temperament <== external_inputs[14];
    frogVerify.jump <== external_inputs[15];
    frogVerify.speed <== external_inputs[16];
    frogVerify.intelligence <== external_inputs[17];
    frogVerify.beauty <== external_inputs[18];
    frogVerify.reservedField1 <== external_inputs[19];
    frogVerify.reservedField2 <== external_inputs[20];
    frogVerify.reservedField3 <== external_inputs[21];
    

//
//
//
//

//     signal frogId;
//     signal biome;
//     signal rarity;
//     signal temperament;
//     signal jump;
//     signal speed;
//     signal intelligence;
//     signal beauty;
//     signal timestampSigned;
//     signal ownerSemaphoreId;
//     // reserved fields
//     signal reservedField1;
//     signal reservedField2;
//     signal reservedField3;

//     // Signer of the frog: EdDSA public key
//     signal frogSignerPubkeyAx;
//     signal frogSignerPubkeyAy;

//     // Signature of the frog: EdDSA signature
//     signal frogSignatureR8x;
//     signal frogSignatureR8y;
//     signal frogSignatureS;

//     // Owner's Semaphore identity, private
//     signal semaphoreIdentityNullifier;
//     signal semaphoreIdentityTrapdoor;

//     // External nullifier, used to tie together nullifiers within a single category.
//     signal externalNullifier;

//     // Watermark allows prover to tie a proof to a challenge. It's unconstrained,
//     // but included in the proof.
//     signal watermark;

//     // assigning external_inputs to interior signals
//     frogId <== external_inputs[0];
//     timestampSigned <== external_inputs[1];
//     ownerSemaphoreId <== external_inputs[2];
//     frogSignerPubkeyAx <== external_inputs[3];
//     frogSignerPubkeyAy <== external_inputs[4];
//     semaphoreIdentityTrapdoor <== external_inputs[5];
//     semaphoreIdentityNullifier <== external_inputs[6];
//     watermark <== external_inputs[7];
//     frogSignatureR8x <== external_inputs[8];
//     frogSignatureR8y <== external_inputs[9];
//     frogSignatureS <== external_inputs[10];
//     externalNullifier <== external_inputs[11];
//     biome <== external_inputs[12];
//     rarity <== external_inputs[13];
//     temperament <== external_inputs[14];
//     jump <== external_inputs[15];
//     speed <== external_inputs[16];
//     intelligence <== external_inputs[17];
//     beauty <== external_inputs[18];
//     reservedField1 <== external_inputs[19];
//     reservedField2 <== external_inputs[20];
//     reservedField3 <== external_inputs[21];


// // start of actual frog circuit logic.
// // Calculate "message" representing the frog, which is a hash of the fields.
//     signal frogMessageHash <== Poseidon(13)([
//         frogId,
//         biome,
//         rarity,
//         temperament,
//         jump,
//         speed,
//         intelligence,
//         beauty,
//         timestampSigned,
//         ownerSemaphoreId,
//         reservedField1,
//         reservedField2,
//         reservedField3
//     ]);

//     // Verify frog signature
//     EdDSAPoseidonVerifier()(
//         1,
//         frogSignerPubkeyAx,
//         frogSignerPubkeyAy,
//         frogSignatureS,
//         frogSignatureR8x,
//         frogSignatureR8y,
//         frogMessageHash
//     );

//     // Verify semaphore private identity matches the frog owner semaphore ID.
//     signal semaphoreSecret <== Poseidon(2)([
//         semaphoreIdentityNullifier,
//         semaphoreIdentityTrapdoor
//     ]);
//     signal semaphoreIdentityCommitment <== Poseidon(1)([semaphoreSecret]);
//     ownerSemaphoreId === semaphoreIdentityCommitment;

//     // Calculate nullifier
//     signal output nullifierHash <== Poseidon(2)([externalNullifier, semaphoreIdentityNullifier]);

//     // Dummy constraint on watermark to make sure it can't be compiled out.
//     signal watermarkSquared <== watermark * watermark;


    // nullifierHash[0] <== frogVerify.nullifierHash;

    ivc_output[0] <== ivc_input[0] + 1;
}

component main {public [ivc_input]} = frogIVC();