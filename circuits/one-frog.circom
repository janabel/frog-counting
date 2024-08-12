pragma circom 2.1.4;

include "../../../../node_modules/circomlib/circuits/poseidon.circom";
include "../../../../node_modules/circomlib/circuits/eddsaposeidon.circom";

// Claim being proved:
// 1. The owner owns the frog: the owner's semaphore identity matches the
// frog's ownerSemaphoreId. And the owner's identity will be kept private.
// 2. The frog data is signed by a signer with the specified EdDSA pubkey.
// 3. Additionally a nullfier is calculated.
template EdDSAFrogPCD () {
    // Fields representing a frog
    signal input frogId;
    signal input biome;
    signal input rarity;
    signal input temperament;
    signal input jump;
    signal input speed;
    signal input intelligence;
    signal input beauty;
    signal input timestampSigned;
    signal input ownerSemaphoreId;
    // reserved fields
    signal input reservedField1;
    signal input reservedField2;
    signal input reservedField3;

    // Signer of the frog: EdDSA public key
    signal input frogSignerPubkeyAx;
    signal input frogSignerPubkeyAy;

    // Signature of the frog: EdDSA signaure
    signal input frogSignatureR8x;
    signal input frogSignatureR8y;
    signal input frogSignatureS;

    // Owner's Semaphore identity, private
    signal input semaphoreIdentityNullifier;
    signal input semaphoreIdentityTrapdoor;

    // External nullifier, used to tie together nullifiers within a single category. 
    signal input externalNullifier;

    // Watermark allows prover to tie a proof to a challenge. It's unconstrained,
    // but included in the proof.
    signal input watermark;

    // Calculate "message" representing the frog, which is a hash of the fields.
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
    signal output nullifierHash <== Poseidon(2)([externalNullifier, semaphoreIdentityNullifier]);

    // Dummy constraint on watermark to make sure it can't be compiled out.
    signal watermarkSquared <== watermark * watermark;
}

component main { public [
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
    reservedField3,
    frogSignerPubkeyAx,
    frogSignerPubkeyAy,
    externalNullifier,
    watermark
] } = EdDSAFrogPCD();

/* INPUT = {
    "frogId": "10",
    "timestampSigned": "1723063971239",
    "ownerSemaphoreId": "9964141043217120936664326897183667118469716023855732146334024524079553329018",
    "frogSignerPubkeyAx": "6827523554590803092735941342538027861463307969735104848636744652918854385131",
    "frogSignerPubkeyAy": "19079678029343997910757768128548387074703138451525650455405633694648878915541",
    "semaphoreIdentityTrapdoor": "135040283343710365777958365424694852760089427911973547434460426204380274744",
    "semaphoreIdentityNullifier": "358655312360435269311557940631516683613039221013826685666349061378483316589",
    "watermark": "2718",
    "frogSignatureR8x": "1482350313869864254042595459421095897218687816166241224483874238825079857068",
    "frogSignatureR8y": "21443280299859662584655395271110089155773803041593918291203552153143944893901",
    "frogSignatureS": "1391256727295516554759691112683783404841502861038527717248540264088174477546",
    "externalNullifier": "10661416524110617647338817740993999665252234336167220367090184441007783393",
    "biome": "3",
    "rarity": "1",
    "temperament": "11",
    "jump": "1",
    "speed": "1",
    "intelligence": "0",
    "beauty": "3",
    "reservedField1": "0",
    "reservedField2": "0",
    "reservedField3": "0"
} */
