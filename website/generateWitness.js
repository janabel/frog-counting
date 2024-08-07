const snarkjs = require("snarkjs");
const fs = require("fs");
const path = require("path");

async function generateProof() {
  // Load the WASM file
  const wasmUrl = "multiplier.wasm"; // Adjust the path to your WASM file
  const inputFile = document.getElementById("a").value;
  const bFile = document.getElementById("b").value;

  // Create the input object
  const input = {
    a: parseInt(inputFile),
    b: parseInt(bFile),
  };

  // Fetch and instantiate the WASM file
  const response = await fetch(wasmUrl);
  const wasmBuffer = await response.arrayBuffer();
  const wasm = await WebAssembly.compile(wasmBuffer);
  const instance = await WebAssembly.instantiate(wasm);

  // Generate the witness
  const witness = await snarkjs.wasm.calculateWitness(instance.exports, input);

  // Load the `.zkey` file (proving key)
  const zkeyUrl = "multiplier_final.zkey"; // Adjust the path to your zkey file
  const zkeyResponse = await fetch(zkeyUrl);
  const zkeyBuffer = await zkeyResponse.arrayBuffer();
  const zkey = new Uint8Array(zkeyBuffer);

  // Generate the proof
  const proof = await snarkjs.groth16.prove(zkey, witness);

  // Display the proof
  document.getElementById("result").textContent = JSON.stringify(
    proof,
    null,
    2
  );
}
