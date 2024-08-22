import { IssuePOD } from "./IssuePOD";
import { UserInput } from "./UserInput";
import { useState } from "react";
import { groth16 } from "snarkjs";

export function Verify() {
  const [verifyStatus, setVerifyStatus] = useState(false);

  const verify = async () => {
    const vkey_element = document.getElementById(
      "vkey-input"
    ) as HTMLInputElement | null;
    const public_signals_element = document.getElementById(
      "public-signals-input"
    ) as HTMLInputElement | null;
    const proof_element = document.getElementById(
      "proof-input"
    ) as HTMLInputElement | null;

    if (!vkey_element || !public_signals_element || !proof_element) {
      console.log("please provide vkey, public signals, and proof!");
      return;
    }

    const vkey_input = JSON.parse(vkey_element.value);
    const public_signals_input = JSON.parse(public_signals_element.value);
    const proof_input = JSON.parse(proof_element.value);

    // trying to verify the proof, throws an error if groth16.verify throws and error
    try {
      console.log(
        "vkey",
        vkey_input,
        "publicSignals",
        public_signals_input,
        "proof",
        proof_input
      );
      await groth16.verify(vkey_input, public_signals_input, proof_input);
      setVerifyStatus(true);
      console.log("successfully verified...");
    } catch (error) {
      console.log("Error verifying proof...", error);
      return;
    }
  };

  return (
    <div className="flex flex-col gap-4 my-4">
      <div id="verify-box">
        <h1 className="text-xl font-bold mb-2">Verify Proof</h1>
        <UserInput id="vkey-input" placeholder="Verification key" />
        <UserInput id="public-signals-input" placeholder="Public signals" />
        <UserInput id="proof-input" placeholder="Groth16 proof" />

        <div>
          <button className="btn btn-primary" onClick={verify}>
            Verify Proof
          </button>
        </div>

        {verifyStatus ? <h1>Proof was verified!</h1> : <h1></h1>}
      </div>

      <div id="pod-issuer-box">
        {verifyStatus ? <IssuePOD></IssuePOD> : <div></div>}
      </div>
    </div>
  );
}
