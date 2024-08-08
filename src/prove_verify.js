import { groth16 } from "snarkjs";

let proof = undefined;
let publicSignals = undefined;

document.getElementById("prove-button")
  .addEventListener("click", async function () {
    const a_char = document.getElementById("a").value;
    const b_char = document.getElementById("b").value;
    const a_val = parseInt(a_char);
    const b_val = parseInt(b_char);

    ({ proof, publicSignals } = await groth16.fullProve(
      { a: a_val, b: b_val },
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

const vkeyResponse = await fetch("./multiplier_vkey.json");
const vkey = await vkeyResponse.json();
// const publicSignalsResponse = await fetch("./public.json");
// const publicSignals = await publicSignalsResponse.json();

document.getElementById("verify-proof-button")
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




function isValidProof(parsed) {
  // Check if the object has the required properties and their types
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

function assert(condition, message) {
  console.log(condition);
  if (!condition) {
    throw new Error(message || "Assertion failed");
  }
}
