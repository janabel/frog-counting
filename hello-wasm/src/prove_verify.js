import init, { greet, add, run_keccak } from "./pkg/hello_wasm.js";
init().then(() => {
  greet("WebAssembly");
});

const addButton = document.getElementById("add-button");
addButton.addEventListener("click", function () {
  const input1 = document.getElementById("input1").value;
  const input2 = document.getElementById("input2").value;

  console.log(input1);

  const sum = document.getElementById("sum");
  sum.innerText += " " + add(input1, input2).toString();

  console.log("set sum text");

  console.log("running keccak_chain.rs full_flow");
  run_keccak();
});

// Copied from https://github.com/janabel/POD-counting/blob/single-frog/src/prove_verify.js

import { generateSnarkMessageHash, hexToBigInt, fromHexString } from "@pcd/util";
import { buildEddsa } from 'circomlibjs';
import { groth16 } from "snarkjs";
import { Buffer } from 'buffer';

let proof = undefined;
let publicSignals = undefined;

const vkeyResponse = await fetch("./frog_vkey.json");
const vkey = await vkeyResponse.json();
const STATIC_ZK_EDDSA_FROG_PCD_NULLIFIER = generateSnarkMessageHash(
  "hard-coded-zk-eddsa-frog-pcd-nullifier"
);
const CZ_SEMPAHORE_ID_TRAPDOOR = "135040283343710365777958365424694852760089427911973547434460426204380274744";
const CZ_SEMPAHORE_ID_NULLIFIER = "358655312360435269311557940631516683613039221013826685666349061378483316589";

// Check if the object has the required properties and their types
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

  console.log("semaphoreIDtrapdoor", semaphoreIDtrapdoor)
  const rawJSON = JSON.parse(rawFrog)

  assert(rawJSON.type == "eddsa-frog-pcd")
  const frogPCD = rawJSON.pcd
  const frogJSON = JSON.parse(frogPCD)
  const eddsaPCD = frogJSON.eddsaPCD
  const frogData = frogJSON.data
  const { name, description, imageUrl,...frogInfo } = frogData;

  const pcdJSON= JSON.parse(eddsaPCD.pcd)
  
  assert(pcdJSON.type == "eddsa-pcd")
  const signature = pcdJSON.proof.signature

  const eddsa = await buildEddsa();
  const rawSig = eddsa.unpackSignature(
      fromHexString(signature)
  );
  const frogSignatureR8x = eddsa.F.toObject(rawSig.R8[0]).toString();
  const frogSignatureR8y = eddsa.F.toObject(rawSig.R8[1]).toString();
  const frogSignatureS = rawSig.S.toString();

  return {...frogInfo, 
    "frogSignerPubkeyAx": hexToBigInt(pcdJSON.claim.publicKey[0]).toString(),
    "frogSignerPubkeyAy": hexToBigInt(pcdJSON.claim.publicKey[1]).toString(),
    "semaphoreIdentityTrapdoor": semaphoreIDtrapdoor,
    "semaphoreIdentityNullifier": semaphoreIDnullifier,
    "watermark": "2718", // ?
    "frogSignatureR8x": frogSignatureR8x,
    "frogSignatureR8y": frogSignatureR8y,
    "frogSignatureS": frogSignatureS,
    "externalNullifier": STATIC_ZK_EDDSA_FROG_PCD_NULLIFIER,
    "reservedField1": "0",
    "reservedField2": "0",
    "reservedField3": "0"
  }
}

document.getElementById("prove-button").addEventListener("click", async function () {
  const frogInput = document.getElementById("frog-input").value;
  const semaphoreTrap = document.getElementById("id-trapdoor").value || CZ_SEMPAHORE_ID_TRAPDOOR;
  const semaphoreNull = document.getElementById("id-nullifier").value || CZ_SEMPAHORE_ID_NULLIFIER;
  console.log("semaphoreID0", semaphoreTrap)


  const circuitInputs = await parseFrog(frogInput, semaphoreTrap, semaphoreNull);

  console.log("circuitInputs", circuitInputs);

  try {
    ({ proof, publicSignals } = await groth16.fullProve(
      circuitInputs,
      "./frog.wasm",
      "./frog_final.zkey"
    ));
    console.log("publicSignals", publicSignals);
    console.log("proof", proof);
  } catch (error) {
    alert(`Invalid signature or frog.\n${error.message}`);
  }
  

  
  let resultHeader = document.createElement("h2");
  resultHeader.innerText = "Result";

  let oldProofBox = document.createElement("text-box");
  oldProofBox.innerText =
    "Proof: " +
    JSON.stringify(proof) +
    "\n" +
    "Public Signals: " +
    publicSignals.toString();

  let proofBox = document.createElement("textarea");
  proofBox.innerHTML = JSON.stringify(proof, null, 2);

  let publicSignalsBox = document.createElement("textarea");
  publicSignalsBox.innerHTML = JSON.stringify(publicSignals, null, 2);

  const proofResult = document.getElementById("proof-result");
  proofResult.appendChild(resultHeader);
  // proofResult.appendChild(document.createTextNode("Proof:\n\n"));
  proofResult.appendChild(proofBox);
  // proofResult.appendChild(document.createTextNode("Public Signals:\n"));
  proofResult.appendChild(publicSignalsBox);
  // proofResult.appendChild(oldProofBox);
});



document.getElementById("verify-proof-button").addEventListener("click", async function () {
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