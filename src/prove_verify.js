import {
  generateSnarkMessageHash,
  hexToBigInt,
  fromHexString,
} from "@pcd/util";
import { buildEddsa, buildPoseidon } from "circomlibjs";
import { groth16 } from "snarkjs";
import { Buffer } from "buffer";
import { parse } from "path-browserify";
// import { fs } from "fs";

let proof = undefined;
let publicSignals = undefined;

const vkeyResponse = await fetch("./frog_vkey.json");
const vkey = await vkeyResponse.json();
const STATIC_ZK_EDDSA_FROG_PCD_NULLIFIER = generateSnarkMessageHash(
  "hard-coded-zk-eddsa-frog-pcd-nullifier"
);
const CZ_SEMPAHORE_ID_TRAPDOOR =
  "135040283343710365777958365424694852760089427911973547434460426204380274744";
const CZ_SEMPAHORE_ID_NULLIFIER =
  "358655312360435269311557940631516683613039221013826685666349061378483316589";
// const CZ_SEMPAHORE_ID_TRAPDOOR =
//   "135040283343710365777958365424694852760089427911973547434460426204380274744";
// const CZ_SEMPAHORE_ID_NULLIFIER =
//   "358655312360435269311557940631516683613039221013826685666349061378483316589";

// check if the object has the required properties and their types
// TODO: probably remove this in the end because want to abstract away proof from user.
function isValidProof(parsed) {
  return (
    parsed &&
    typeof parsed === "object" &&
    parsed !== null &&
    "pi_a" in parsed &&
    Array.isArray(parsed.pi_a) &&
    parsed.pi_a.length === 3 &&
    "pi_b" in parsed &&
    Array.isArray(parsed.pi_b) &&
    parsed.pi_b.length === 3 &&
    "pi_c" in parsed &&
    Array.isArray(parsed.pi_c) &&
    parsed.pi_c.length === 3 &&
    "protocol" in parsed &&
    typeof parsed.protocol === "string" &&
    "curve" in parsed &&
    typeof parsed.curve === "string"
  );
}

// Custom assert that logs to console?
function assert(condition, message = "Assertion failed") {
  console.log(condition);
  if (!condition) {
    throw new Error(message);
  }
}

// Parse serialized frog to one-frog.circom input
async function parseFrog(rawFrog, semaphoreIDtrapdoor, semaphoreIDnullifier) {
  /* INPUT = {
    "frogId": "10",
    "timestampSigned": "1723063971239",
    "ownerSemaphoreId": "9964141043217120936664326897183667118469716023855732146334024524079553329018",
    "frogSignerPubkeyAx": "6827523554590803092735941342538027861463307969735104848636744652918854385131",
    "frogSignerPubkeyAy": "19079678029343997910757768128548387074703138451525650455405633694648878915541",
    "semaphoreIdentityTrapdoor": "135040283343710365777958365424694852760089427911973547434460426204380274744",
    "semaphoreIdentityNullifier": "358655312360435269311557940631516683613039221013826685666349061378483316589",
    "watermark": 2718,
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

  console.log("semaphoreIDtrapdoor", semaphoreIDtrapdoor);
  const rawJSON = JSON.parse(rawFrog);

  assert(rawJSON.type == "eddsa-frog-pcd");
  const frogPCD = rawJSON.pcd;
  const frogJSON = JSON.parse(frogPCD);
  const eddsaPCD = frogJSON.eddsaPCD;
  const frogData = frogJSON.data;
  const { name, description, imageUrl, ...frogInfo } = frogData;

  assert(pcdJSON.type == "eddsa-pcd");
  const signature = pcdJSON.proof.signature;
  const pcdJSON = JSON.parse(eddsaPCD.pcd);

  const eddsa = await buildEddsa();
  const rawSig = eddsa.unpackSignature(fromHexString(signature));
  const frogSignatureR8x = eddsa.F.toObject(rawSig.R8[0]).toString();
  const frogSignatureR8y = eddsa.F.toObject(rawSig.R8[1]).toString();
  const frogSignatureS = rawSig.S.toString();

  return {
    ...frogInfo,
    frogSignerPubkeyAx: hexToBigInt(pcdJSON.claim.publicKey[0]).toString(),
    frogSignerPubkeyAy: hexToBigInt(pcdJSON.claim.publicKey[1]).toString(),
    semaphoreIdentityTrapdoor: semaphoreIDtrapdoor,
    semaphoreIdentityNullifier: semaphoreIDnullifier,
    watermark: "2718", // ?
    frogSignatureR8x: frogSignatureR8x,
    frogSignatureR8y: frogSignatureR8y,
    frogSignatureS: frogSignatureS,
    externalNullifier: STATIC_ZK_EDDSA_FROG_PCD_NULLIFIER.toString(),
    reservedField1: "0",
    reservedField2: "0",
    reservedField3: "0",
  };
}

// function for downloading json from website (can't use fs in browser)
function downloadJSON(jsonObject, fileName) {
  const jsonString = JSON.stringify(jsonObject, null, 2);
  const blob = new Blob([jsonString], { type: "application/json" });
  const url = URL.createObjectURL(blob);
  const a = document.createElement("a");
  a.href = url;
  a.download = fileName;
  document.body.appendChild(a);
  a.click();
  document.body.removeChild(a);
  URL.revokeObjectURL(url);
}

// function for parsing an array of serializedFrogs
async function parseFrogs(serializedFrogs) {
  const promises = serializedFrogs.map(async (serializedFrog) => {
    const result = await parseFrog(serializedFrog);
    return result;
  });

  const results = await Promise.all(promises);
  return results;
}

// function for computing poseidon hash on input array
async function computePoseidonHash(inputArray) {
  const poseidon = await buildPoseidon();
  const hash = poseidon.F.toString(poseidon(inputArray));
  return hash;
}

async function getFrogHashInput(parsedFrog) {
  console.log("parsedFrog length", parsedFrog.length);
  return [
    BigInt(parsedFrog.frogId),
    BigInt(parsedFrog.biome),
    BigInt(parsedFrog.rarity),
    BigInt(parsedFrog.temperament),
    BigInt(parsedFrog.jump),
    BigInt(parsedFrog.speed),
    BigInt(parsedFrog.intelligence),
    BigInt(parsedFrog.beauty),
    BigInt(parsedFrog.timestampSigned),
    BigInt(parsedFrog.ownerSemaphoreId),
    BigInt(parsedFrog.reservedField1),
    BigInt(parsedFrog.reservedField2),
    BigInt(parsedFrog.reservedField3),
  ];
}

document
  .getElementById("prove-button")
  .addEventListener("click", async function () {
    // getting semaphore ID from user input
    const semaphoreTrap =
      document.getElementById("id-trapdoor").value || CZ_SEMPAHORE_ID_TRAPDOOR;
    const semaphoreNull =
      document.getElementById("id-nullifier").value ||
      CZ_SEMPAHORE_ID_NULLIFIER;

    // serializedFrogs = array of serialized frogs
    const serializedFrogs = document
      .getElementById("frog-input")
      .value.split("\n\n");

    // create array of parsed frogs
    let parsedFrogs = await parseFrogs(serializedFrogs);
    console.log("parsedFrogs", parsedFrogs);

    // create an array of [frogMsgHash, parsedfrog]
    let frogHash_and_frog_array = await Promise.all(
      parsedFrogs.map(async (parsedFrog) => {
        const frogHashInput = await getFrogHashInput(parsedFrog);
        const frogMsgHash = await computePoseidonHash(frogHashInput);
        return [frogMsgHash, parsedFrog];
      })
    );

    frogHash_and_frog_array.sort((a, b) => a[0] - b[0]);
    console.log("sorted frogHash_and_frog_array", frogHash_and_frog_array);

    let sortedFrogArray = frogHash_and_frog_array.map((item) => item[1]); // just the frog objects, no more hashes
    console.log("sorted sortedFrogArray", sortedFrogArray);

    const frogsJSon = sortedFrogArray.reduce(
      (accumulator, currentValue, index) => {
        accumulator[index + 1] = currentValue;
        return accumulator;
      },
      {}
    );

    console.log(frogsJSon);
    // downloadJSON(frogsJSon, `frogCircuitInputs.json`);
  });

document
  .getElementById("verify-proof-button")
  .addEventListener("click", async function () {
    if (!publicSignals) {
      console.log("did not provide input values yet");
      return;
    }
    const verifyResult = document.getElementById("verify-result");

    console.log("button clicked!");
    const rawProof = document.getElementById("proof").value;

    // checking that the proof is a JSON
    let proof = undefined;
    try {
      proof = JSON.parse(rawProof);
      console.log(proof);
      console.log("got valid json");
    } catch (error) {
      verifyResult.innerText = "Please enter a valid proof!";
      console.log("caught an error:", error.message);
      return;
    }

    // checking that the proof is a JSON of the correct proof format
    if (!isValidProof(proof)) {
      verifyResult.innerText = "Please enter a valid proof!";
      return;
    }
    // checking that the proof is a JSON of the correct proof format
    if (!isValidProof(proof)) {
      verifyResult.innerText = "Please enter a valid proof!";
      return;
    }

    // trying to verify the proof, throws and error if groth16.verify throws and error
    let verify = undefined;
    try {
      console.log("vkey", vkey, "publicSignals", publicSignals, "proof", proof);
      verify = await groth16.verify(vkey, publicSignals, proof);
      console.log("successfully verified...");
    } catch (error) {
      verifyResult.innerText = "Error verifying proof...";
      return;
    }

    // update text of verifyResult div with status of verification
    if (verify) {
      verifyResult.innerText = "Proof was verified!";
    } else {
      verifyResult.innerText = "Proof was rejected :(";
    }
  });
