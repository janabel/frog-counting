import {
    generateSnarkMessageHash,
    hexToBigInt,
    fromHexString,
} from "@pcd/util";
import { buildEddsa, buildPoseidon } from "circomlibjs";
import { groth16 } from "snarkjs";

const STATIC_ZK_EDDSA_FROG_PCD_NULLIFIER = generateSnarkMessageHash(
"hard-coded-zk-eddsa-frog-pcd-nullifier"
);

function assert(condition: boolean, message = "Assertion failed") {
    console.log(condition);
    if (!condition) {
        throw new Error(message);
    }
}
  
export async function parseFrog(rawJSON: Object, semaphoreIDtrapdoor: string, semaphoreIDnullifier: string) {
    assert(rawJSON.type == "eddsa-frog-pcd");
    const frogPCD = rawJSON.pcd;
    const frogJSON = JSON.parse(frogPCD);
    const eddsaPCD = frogJSON.eddsaPCD;
    const frogData = frogJSON.data;
    const { name, description, imageUrl, ...frogInfo } = frogData;
    const pcdJSON = JSON.parse(eddsaPCD.pcd);
    const signature = pcdJSON.proof.signature;
    assert(pcdJSON.type == "eddsa-pcd");
  
    const eddsa = await buildEddsa();
    const rawSig = eddsa.unpackSignature(fromHexString(signature));
    const frogSignatureR8x = eddsa.F.toObject(rawSig.R8[0]).toString();
    const frogSignatureR8y = eddsa.F.toObject(rawSig.R8[1]).toString();
    const frogSignatureS = rawSig.S.toString();
  
    return {
      ...Object.fromEntries(
        Object.entries(frogInfo).map(([key, value]) => [key, (value as any).toString()])
      ),
      frogSignerPubkeyAx: hexToBigInt(pcdJSON.claim.publicKey[0]).toString(),
      frogSignerPubkeyAy: hexToBigInt(pcdJSON.claim.publicKey[1]).toString(),
      semaphoreIdentityTrapdoor: semaphoreIDtrapdoor,
      semaphoreIdentityNullifier: semaphoreIDnullifier,
      watermark: "2718",
      frogSignatureR8x: frogSignatureR8x,
      frogSignatureR8y: frogSignatureR8y,
      frogSignatureS: frogSignatureS,
      externalNullifier: STATIC_ZK_EDDSA_FROG_PCD_NULLIFIER.toString(),
      reservedField1: "0",
      reservedField2: "0",
      reservedField3: "0",
    };
}