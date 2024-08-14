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

    // nullifierHash[0] <== frogVerify.nullifierHash;

    log(0);
    log(0);
    log(0);
    log(0);
    log(0);
    log(0);
    log(0);
    log(0);
    log(0);
    log(0);
    log(0);

    ivc_output[0] <== ivc_input[0] + 1;
}

component main {public [ivc_input]} = frogIVC();