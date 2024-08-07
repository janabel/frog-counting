// export async function verify() {
//   const proof = document.getElementById("proof").value;
//   console.log(proof);
// }

document
  .getElementById("verify-proof-button")
  .addEventListener("click", async function () {
    const proof = document.getElementById("proof").value;
    // console.log(proof);

    const zkeyPath = "path/to/circuit.zkey";
    const proofPath = "path/to/proof.json";
    const publicPath = "path/to/public.json";

    const zkey = JSON.parse(fs.readFileSync(zkeyPath, "utf8"));
    const publicInputs = JSON.parse(fs.readFileSync(publicPath, "utf8"));

    // Verify the proof
    const isValid = await snarkjs.groth16.verify(zkey, publicInputs, proof);

    if (isValid) {
      console.log("Proof is valid!");
    } else {
      console.log("Proof is invalid.");
    }
  });
