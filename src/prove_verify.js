import { groth16 } from "snarkjs";

let proof = undefined;
let publicSignals = undefined;

const vkeyResponse = await fetch("./multiplier_vkey.json");
const vkey = await vkeyResponse.json();

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
function assert(condition, message) {
  console.log(condition);
  if (!condition) {
    throw new Error(message || "Assertion failed");
  }
}

// Parse serialized frog to one-frog.circom input
function parseFrog(rawFrog){
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

  return {
    "a": 3,
    "b": 11
  }
}

document.getElementById("prove-button").addEventListener("click", async function () {
  const frog_input = document.getElementById("frog-input").value;

  ({ proof, publicSignals } = await groth16.fullProve(
    parseFrog(frog_input),
    "./multiplier.wasm",
    "./multiplier_final.zkey"
  ));
  console.log(publicSignals);
  console.log(proof);

  let resultHeader = document.createElement("h2");
  resultHeader.innerText = "Result";

  let proofBox = document.createElement("text-box");
  proofBox.innerText =
    "Proof: " +
    JSON.stringify(proof) +
    "\n" +
    "Public Signals: " +
    publicSignals.toString();

  const proofResult = document.getElementById("proof-result");
  proofResult.appendChild(resultHeader);
  proofResult.appendChild(proofBox);
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