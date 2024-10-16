import { PODData } from "@parcnet-js/podspec";
import { PODName, PODStringValue } from "@pcd/pod";

export type stringPOD = {
  entries: Record<PODName, PODStringValue>;
  signature: string;
  signerPublicKey: string;
};

// function assert(condition: boolean, message = "Assertion failed") {
//   console.log(condition);
//   if (!condition) {
//     throw new Error(message);
//   }
// }

// function base64ToHex(base64String: string): string {
//   const binaryString = atob(base64String);
//   let hexString = "";
//   for (let i = 0; i < binaryString.length; i++) {
//     const hex = binaryString.charCodeAt(i).toString(16).padStart(2, "0");
//     hexString += hex;
//   }
//   return hexString;
// }

// function extractSignerPublicKeyCoordinates(base64PubKey: string): {
//   frogSignerPubkeyAx: string;
//   frogSignerPubkeyAy: string;
// } {
//   // Step 1: Decode the Base64 public key
//   const binaryPubKey = Uint8Array.from(atob(base64PubKey), (c) =>
//     c.charCodeAt(0)
//   );

//   // Step 2: Check the length of the decoded public key
//   if (binaryPubKey.length !== 32) {
//     throw new Error("Invalid public key length. Expected 32 bytes.");
//   }

//   // Step 3: Extract x and y coordinates
//   const frogSignerPubkeyAx = Array.from(binaryPubKey.slice(0, 16))
//     .map((byte) => byte.toString(16).padStart(2, "0"))
//     .join(""); // First 16 bytes (128 bits) for x
//   const frogSignerPubkeyAy = Array.from(binaryPubKey.slice(16, 32))
//     .map((byte) => byte.toString(16).padStart(2, "0"))
//     .join(""); // Last 16 bytes (128 bits) for y

//   return {
//     frogSignerPubkeyAx,
//     frogSignerPubkeyAy,
//   };
// }

export interface frogPOD {
  frogId: string;
  biome: string;
  rarity: string;
  temperament: string;
  jump: string;
  speed: string;
  intelligence: string;
  beauty: string;
  timestampSigned: string;
  ownerSemaphoreId: string;
  frogSignerPubkeyAx: string;
  frogSignerPubkeyAy: string;
  semaphoreIdentityCommitment: string;
  watermark: string;
  frogSignatureR8x: string;
  frogSignatureR8y: string;
  frogSignatureS: string;
  externalNullifier: string;
  reservedField1: string;
  reservedField2: string;
  reservedField3: string;
}

// use while waiting for zupass
export async function parseFrogPOD(
  frogPOD: PODData,
  semaphoreIdentityCommitment: bigint
): Promise<frogPOD> {
  // dummy test pods have all entries already formatted correctly

  const entries = frogPOD.entries;

  return {
    frogId: entries.frogId.value.toString(),
    biome: entries.biome.value.toString(),
    rarity: entries.rarity.value.toString(),
    temperament: entries.temperament.value.toString(),
    jump: entries.jump.value.toString(),
    speed: entries.speed.value.toString(),
    intelligence: entries.intelligence.value.toString(),
    beauty: entries.beauty.value.toString(),
    timestampSigned: entries.timestampSigned.value.toString(),
    ownerSemaphoreId: entries.ownerSemaphoreId.value.toString(),
    frogSignerPubkeyAx: entries.frogSignerPubkeyAx.value.toString(),
    frogSignerPubkeyAy: entries.frogSignerPubkeyAy.value.toString(),
    semaphoreIdentityCommitment: semaphoreIdentityCommitment.toString(),
    watermark: entries.watermark.value.toString(),
    frogSignatureR8x: entries.frogSignatureR8x.value.toString(),
    frogSignatureR8y: entries.frogSignatureR8y.value.toString(),
    frogSignatureS: entries.frogSignatureS.value.toString(),
    externalNullifier: entries.externalNullifier.value.toString(),
    reservedField1: entries.reservedField1.value.toString(),
    reservedField2: entries.reservedField2.value.toString(),
    reservedField3: entries.reservedField3.value.toString(),
  };
}
