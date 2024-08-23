pragma circom 2.1.5;

include "./frog.circom";
include "../circomlib/circuits/comparators.circom";

// IVC formatted frogCounter circuit
template frogIVC () {
    // in javascript, already preprocessed external_inputs so that they are sorted by frog_msg_hash in INCREASING order.
    // in javascript, also already removed duplicates.
    // ivc_input = frog_msg_hash (from previous frog) & counter of # frogs so far.  
    // circuit checks that new frog_msg_hash is greater, and then returns new hash as ivc_output. 

    // can split frogMsgHash in base 2^128 before reading into ivc_input, i.e. 
    // frogMsgHash = frogMsgHash_small_old + 2^128 * frogMsgHash_big_old
    // ivc_input = [frogMsgHash_small_old, frogMsgHash_big_old, frogCounter];
    signal input ivc_input[3];
    signal input external_inputs[22];
    signal output ivc_output[3];

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

    signal frogMessageHashSmall;
    frogMessageHashSmall <== frogVerify.frogMessageHashSmall;
    signal frogMessageHashBig;
    frogMessageHashBig <== frogVerify.frogMessageHashBig;

    // now check that old ivc_output < new frogMessageHash. just check strictly < b/c javascript will do dedup for us.
    // do a lessThan check bc greater than circuit is just using the lessThan circuit. to be as direct as possible.
    // compute (ivc_input[1] < frogMessageHashBig)  OR (frogMessageHashBig = ivc_input[1] AND ivc_input[0] < frogMessageHashSmall)

    component bigLessThan = LessThan(130);
    bigLessThan.in[0] <== ivc_input[1];
    bigLessThan.in[1] <== frogMessageHashBig;
    signal bigLessThanResult <== bigLessThan.out;

    component bigEqual = IsEqual();
    bigEqual.in[0] <== frogMessageHashBig;
    bigEqual.in[1] <== ivc_input[1];
    signal bigEqualResult <== bigEqual.out;

    component smallLessThan = LessThan(130);
    smallLessThan.in[0] <== ivc_input[0];
    smallLessThan.in[1] <== frogMessageHashSmall;
    signal smallLessThanResult <== smallLessThan.out;

    // bigLessThanResult OR (bigEqualResult AND smallLessThanResult)
    signal bigEq_and_smallLess <== bigEqualResult * smallLessThanResult;
    (1-bigLessThanResult)*(1-bigEq_and_smallLess) === 0;

    // put in the new frogMessageHash as ivc_output
    ivc_output[0] <== frogMessageHashSmall;
    ivc_output[1] <== frogMessageHashBig;
    ivc_output[2] <== ivc_input[2] + 1;

}

component main {public [ivc_input]} = frogIVC();