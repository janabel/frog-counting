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
