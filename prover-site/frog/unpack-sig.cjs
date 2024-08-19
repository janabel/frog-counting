const { Buffer } = require('buffer');
const { unpackSignature } = require("@zk-kit/eddsa-poseidon");
const fs = require('fs');
const { fromHexString, hexToBigInt, generateSnarkMessageHash } = require("@pcd/util");



const jsonData = fs.readFileSync("frog/my_frog.json", 'utf8');
const data = JSON.parse(jsonData);
signature = data.pcd.eddsaPCD.pcd.proof.signature


// signature X, Y, s
const circomlib = require('circomlibjs');
const eddsa = circomlib.buildEddsa().then((eddsa) => {
    console.log("eddsa", eddsa)
    const rawSig = eddsa.unpackSignature(
        fromHexString(signature)
    );
    

    console.log("raw R8x", rawSig.R8[0], typeof rawSig.R8[0])
    frogSignatureR8x = eddsa.F.toObject(rawSig.R8[0]).toString();
    frogSignatureR8y = eddsa.F.toObject(rawSig.R8[1]).toString();
    frogSignatureS = rawSig.S.toString();
    console.log("frogSignatureS", frogSignatureS)
    console.log("frogSignatureR8x", frogSignatureR8x)
    console.log("frogSignatureR8y", frogSignatureR8y)
})


// public key
// signerPubKey = data.pcd.eddsaPCD.pcd.claim.publicKey
// frogSignerPubkeyAx = hexToBigInt(signerPubKey[0]).toString();
// frogSignerPubkeyAy = hexToBigInt(signerPubKey[1]).toString();
// console.log("frogSignerPubkeyAx", frogSignerPubkeyAx)
// console.log("frogSignerPubkeyAy", frogSignerPubkeyAy)



// sephamore id JK use the id provided in browser
// const {SemaphoreIdentityPCD, SemaphoreIdentityPCDPackage } = require("@pcd/semaphore-identity-pcd");


// sephamore ID trapdoor and nullifier
const { BigNumber } = require("@ethersproject/bignumber");

id = ["0x4c6e1a7ee594b4f25c595106d46b3bd1be66a584715afb3b6cb72b41c62038", "0xcafde0e7e528ddad4fd452e879dd4c0680a6781dbced5c7284fbb01b96676d"]

trapdoor = BigNumber.from(id[0]).toBigInt().toString()

console.log("trapdoor", trapdoor)

nullifier = BigNumber.from(id[1]).toBigInt().toString()
console.log("nullifier", nullifier)



// external nullifier
const STATIC_ZK_EDDSA_FROG_PCD_NULLIFIER = generateSnarkMessageHash(
    "hard-coded-zk-eddsa-frog-pcd-nullifier"
);

console.log("STATIC_ZK_EDDSA_FROG_PCD_NULLIFIER", STATIC_ZK_EDDSA_FROG_PCD_NULLIFIER)