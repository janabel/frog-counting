const snarkjs = require("snarkjs");
const fs = require("fs");
const path = require("path");

async function generateWitness(a, b) {
  const wasmUrl = "../circuits/build/multiplier_js/multiplier.wasm";

  const input = {
    a: parseInt(inputFile),
    b: parseInt(bFile),
  };

  // Fetch and instantiate the WASM file
  const response = await fetch(wasmUrl);
  const wasmBuffer = await response.arrayBuffer();
  const wasm = await WebAssembly.compile(wasmBuffer);
  const instance = await WebAssembly.instantiate(wasm);

  const witness = await snarkjs.wasm.calculateWitness(instance.exports, input);
  return witness;
}

async function generateProof() {
  const proof = await snarkjs.groth16.prove(zkey, witness);

  // Display the proof
  document.getElementById("result").textContent = JSON.stringify(
    proof,
    null,
    2
  );
  return proof;
}

async function verifyProof() {
  // TODO
}

console.log(snarkjs);
