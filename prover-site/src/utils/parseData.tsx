import {
  generateSnarkMessageHash,
  hexToBigInt,
  fromHexString,
} from "@pcd/util";
import { buildEddsa, buildPoseidon } from "circomlibjs";

const STATIC_ZK_EDDSA_FROG_PCD_NULLIFIER = generateSnarkMessageHash(
  "hard-coded-zk-eddsa-frog-pcd-nullifier"
);

function assert(condition: boolean, message = "Assertion failed") {
  console.log(condition);
  if (!condition) {
    throw new Error(message);
  }
}

function base64ToHex(base64String: string): string {
  const binaryString = atob(base64String);
  let hexString = "";
  for (let i = 0; i < binaryString.length; i++) {
    const hex = binaryString.charCodeAt(i).toString(16).padStart(2, "0");
    hexString += hex;
  }
  return hexString;
}

function extractSignerPublicKeyCoordinates(base64PubKey: string): {
  frogSignerPubkeyAx: string;
  frogSignerPubkeyAy: string;
} {
  // Step 1: Decode the Base64 public key
  const binaryPubKey = Uint8Array.from(atob(base64PubKey), (c) =>
    c.charCodeAt(0)
  );

  // Step 2: Check the length of the decoded public key
  if (binaryPubKey.length !== 32) {
    throw new Error("Invalid public key length. Expected 32 bytes.");
  }

  // Step 3: Extract x and y coordinates
  const frogSignerPubkeyAx = Array.from(binaryPubKey.slice(0, 16))
    .map((byte) => byte.toString(16).padStart(2, "0"))
    .join(""); // First 16 bytes (128 bits) for x
  const frogSignerPubkeyAy = Array.from(binaryPubKey.slice(16, 32))
    .map((byte) => byte.toString(16).padStart(2, "0"))
    .join(""); // Last 16 bytes (128 bits) for y

  return {
    frogSignerPubkeyAx,
    frogSignerPubkeyAy,
  };
}

export async function parseFrogPOD(
  frogPOD: object,
  semaphoreIDCommitment: BigInt
) {
  // dummy test pods have all entries already formatted correctly

  const entries = frogPOD.entries;

  return {
    frogId: entries.frogId.value,
    biome: entries.biome.value,
    rarity: entries.rarity.value,
    temperament: entries.temperament.value,
    jump: entries.jump.value,
    speed: entries.speed.value,
    intelligence: entries.intelligence.value,
    beauty: entries.beauty.value,
    timestampSigned: entries.timestampSigned.value,
    ownerSemaphoreId: entries.ownerSemaphoreId.value,
    frogSignerPubkeyAx: entries.frogSignerPubkeyAx.value,
    frogSignerPubkeyAy: entries.frogSignerPubkeyAy.value,
    semaphoreIDCommitment: semaphoreIDCommitment.toString(),
    watermark: entries.watermark.value,
    frogSignatureR8x: entries.frogSignatureR8x.value,
    frogSignatureR8y: entries.frogSignatureR8y.value,
    frogSignatureS: entries.frogSignatureS.value,
    externalNullifier: entries.externalNullifier.value,
    reservedField1: entries.reservedField1.value,
    reservedField2: entries.reservedField2.value,
    reservedField3: entries.reservedField3.value,
  };
}

export async function parseFrog(
  rawJSON: object,
  semaphoreIDCommitment: BigInt
) {
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
      Object.entries(frogInfo).map(([key, value]) => [
        key,
        (value as any).toString(),
      ])
    ),
    frogSignerPubkeyAx: hexToBigInt(pcdJSON.claim.publicKey[0]).toString(),
    frogSignerPubkeyAy: hexToBigInt(pcdJSON.claim.publicKey[1]).toString(),
    semaphoreIDCommitment: semaphoreIDCommitment.toString(),
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

// const signerPublicKey = frogPOD.signerPublicKey;
// const signature = frogPOD.signature;
// const hexSignature = base64ToHex(signature);

// const eddsa = await buildEddsa();
// const rawSig = eddsa.unpackSignature(fromHexString(hexSignature));
// const frogSignatureR8x = eddsa.F.toObject(rawSig.R8[0]).toString();
// const frogSignatureR8y = eddsa.F.toObject(rawSig.R8[1]).toString();
// const frogSignatureS = rawSig.S.toString();

// // console.log("frogSignatureR8x", frogSignatureR8x);
// // console.log("frogSignatureR8y", frogSignatureR8y);
// // console.log("frogSignatureS", frogSignatureS);

// const { frogSignerPubkeyAx, frogSignerPubkeyAy } =
//   extractSignerPublicKeyCoordinates(signerPublicKey);
