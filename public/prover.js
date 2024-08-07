const snarkjs = require("snarkjs");
const { readFileSync, writeFile } = require("fs");
const path = require("path");
const wc  = require("../circuits/build/multiplier_js/witness_calculator.js");

async function prove() {
  const a_char = document.getElementById("a").value;
  const b_char = document.getElementById("b").value;
  const a = parseInt(a_char);
  const b = parseInt(b_char);

  witness = await generateWitness(a, b);
  console.log(witness);
}

async function generateWitness(a, b) {
  console.log("Current directory:", __dirname);
  const wasmUrl = "../circuits/build/multiplier_js/multiplier2.wasm";

  const input = {
    "a": a,
    "b": b
  };

  const response = await fetch(wasmUrl);
  const wasmBuffer = await response.arrayBuffer();

  // logs, just in wrong format (ascii, we wan't hex)
  console.log(typeof wasmBuffer);
  console.log(wasmBuffer);

  const wasm = await WebAssembly.compile(wasmBuffer);
  const instance = await WebAssembly.instantiate(wasm);

  const witness = await snarkjs.wasm.calculateWitness(instance.exports, input);
  return witness;
}

document.getElementById("prove-button").addEventListener("click", prove);

// async function generateProof() {
//   const proof = await snarkjs.groth16.prove(zkey, witness);

//   // Display the proof
//   document.getElementById("result").textContent = JSON.stringify(
//     proof,
//     null,
//     2
//   );
//   return proof;
// }

// async function verifyProof() {
//   // TODO
// }