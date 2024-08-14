pragma circom 2.1.5;

include "./frog.circom";


// IVC formatted frogCounter circuit
template frogIVC_split () {
    signal input ivc_input[1];
    signal input external_inputs[31];
    // signal output nullifierHash[1];
    signal output ivc_output[1];

    var TWO_POWER_128;
    TWO_POWER_128 = 340282366920938463463374607431768211456;

    component frogVerify = EdDSAFrogPCD();
    frogVerify.frogId <== external_inputs[0];
    frogVerify.timestampSigned <== external_inputs[1];

    signal ownerSemaphoreId_small;
    signal ownerSemaphoreId_big;
    ownerSemaphoreId_small <== external_inputs[2];
    ownerSemaphoreId_big <== external_inputs[3];
    frogVerify.ownerSemaphoreId <== ownerSemaphoreId_small + ownerSemaphoreId_big * TWO_POWER_128;

    signal frogSignerPubKeyAx_small;
    signal frogSignerPubkeyAx_big;
    frogSignerPubKeyAx_small <== external_inputs[4];
    frogSignerPubkeyAx_big <== external_inputs[5];
    frogVerify.frogSignerPubkeyAx <== frogSignerPubKeyAx_small + frogSignerPubkeyAx_big * TWO_POWER_128;

    signal frogSignerPubkeyAy_small;
    signal frogSignerPubkeyAy_big;
    frogSignerPubkeyAy_small <== external_inputs[6];
    frogSignerPubkeyAy_big <== external_inputs[7];
    frogVerify.frogSignerPubkeyAy <== frogSignerPubkeyAy_small + frogSignerPubkeyAy_big * TWO_POWER_128;

    signal semaphoreIdentityTrapdoor_small;
    signal semaphoreIdentityTrapdoor_big;
    semaphoreIdentityTrapdoor_small <== external_inputs[8];
    semaphoreIdentityTrapdoor_big <== external_inputs[9];
    frogVerify.semaphoreIdentityTrapdoor <== semaphoreIdentityTrapdoor_small + semaphoreIdentityTrapdoor_big * TWO_POWER_128;

    signal semaphoreIdentityNullifier_small;
    signal semaphoreIdentityNullifier_big;
    semaphoreIdentityNullifier_small <== external_inputs[10];
    semaphoreIdentityNullifier_big <== external_inputs[11];
    frogVerify.semaphoreIdentityNullifier <== semaphoreIdentityNullifier_small + semaphoreIdentityNullifier_big * TWO_POWER_128;

    frogVerify.watermark <== external_inputs[12];

    // Define and use signals for `frogSignatureR8x`
    signal frogSignatureR8x_small;
    signal frogSignatureR8x_big;
    frogSignatureR8x_small <== external_inputs[13];
    frogSignatureR8x_big <== external_inputs[14];
    frogVerify.frogSignatureR8x <== frogSignatureR8x_small + frogSignatureR8x_big * TWO_POWER_128;

    // Define and use signals for `frogSignatureR8y`
    signal frogSignatureR8y_small;
    signal frogSignatureR8y_big;
    frogSignatureR8y_small <== external_inputs[15];
    frogSignatureR8y_big <== external_inputs[16];
    frogVerify.frogSignatureR8y <== frogSignatureR8y_small + frogSignatureR8y_big * TWO_POWER_128;

    // Define and use signals for `frogSignatureS`
    signal frogSignatureS_small;
    signal frogSignatureS_big;
    frogSignatureS_small <== external_inputs[17];
    frogSignatureS_big <== external_inputs[18];
    frogVerify.frogSignatureS <== frogSignatureS_small + frogSignatureS_big * TWO_POWER_128;

    // Define and use signals for `externalNullifier`
    signal externalNullifier_small;
    signal externalNullifier_big;
    externalNullifier_small <== external_inputs[19];
    externalNullifier_big <== external_inputs[20];
    frogVerify.externalNullifier <== externalNullifier_small + externalNullifier_big * TWO_POWER_128;

    frogVerify.biome <== external_inputs[21];
    frogVerify.rarity <== external_inputs[22];
    frogVerify.temperament <== external_inputs[23];
    frogVerify.jump <== external_inputs[24];
    frogVerify.speed <== external_inputs[25];
    frogVerify.intelligence <== external_inputs[26];
    frogVerify.beauty <== external_inputs[27];
    frogVerify.reservedField1 <== external_inputs[28];
    frogVerify.reservedField2 <== external_inputs[29];
    frogVerify.reservedField3 <== external_inputs[30];

    // nullifierHash[0] <== frogVerify.nullifierHash;

    ivc_output[0] <== ivc_input[0] + 1;
}

component main {public [ivc_input]} = frogIVC_split();