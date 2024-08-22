import { IssuePOD } from "./IssuePOD";
import { UserInput } from "./UserInput";
import { useState } from "react";

export function Verify() {
  const [verifyStatus, setVerifyStatus] = useState(false);

  // dummy verify function that just verifies if nonempty
  // TODO: implement real verify
  const verify = () => {
    const vkey_input = document.getElementById("vkey-input");
    const public_signals_input = document.getElementById(
      "public-signals-input"
    );
    const proof_input = document.getElementById("proof-input");

    if (vkey_input && public_signals_input && proof_input) {
      setVerifyStatus(true);
    } else {
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
