import React from "react";
import { IssuePOD } from "./IssuePOD";
import { useState } from "react";
import init, { verifyRust } from "../../sonobe-rust/pkg/sonobe_rust.js";

async function readSerializedData(path: string) {
  const file_path = path;
  const response = await fetch(file_path);
  const bytes = await response.arrayBuffer();
  const res = new Uint8Array(bytes);
  // console.log("result from path " + path, res);
  return res;
}

export function VerifyRust() {
  const [fileData, setFileData] = useState<Uint8Array>(new Uint8Array([]));
  const [verifyStatus, setVerifyStatus] = useState(false);
  const [numFrogs, setNumFrogs] = useState(0n);

  // helper function for file upload
  const handleFileUpload = (event: React.ChangeEvent<HTMLInputElement>) => {
    const file = event.target.files?.[0];
    if (file) {
      const reader = new FileReader();
      reader.onload = (e) => {
        const arrayBuffer = e.target?.result;
        if (arrayBuffer) {
          const uint8Array = new Uint8Array(arrayBuffer as ArrayBuffer);
          setFileData(uint8Array);
        }
      };
      reader.readAsArrayBuffer(file);
    }
  };

  // call verifyRust from sonobe
  const verify = async () => {
    await init();

    const r1cs_res = await readSerializedData("/frogIVC.r1cs");
    const wasm_res = await readSerializedData("/frogIVC.wasm");
    const nova_pp_res = await readSerializedData("/nova_pp_output.bin");
    const nova_vp_res = await readSerializedData("/nova_vp_output.bin");
    const ivc_proof = fileData;
    console.log("read in data/params");

    // trying to verify the proof, throws an error if groth16.verify throws and error
    try {
      const numFrogs = BigInt(
        verifyRust(r1cs_res, wasm_res, ivc_proof, nova_pp_res, nova_vp_res)
      );
      setNumFrogs(numFrogs);
      setVerifyStatus(true);
    } catch (error) {
      console.log("Error verifying proof...", error);
      return;
    }
  };

  return (
    <div className="flex flex-col gap-4 my-4">
      <input type="file" onChange={handleFileUpload} accept=".bin" />
      <div>
        <button className="btn btn-primary" onClick={verify}>
          Verify Proof
        </button>
        {verifyStatus ? (
          <>
            <h1>Proof was verified!</h1>
            <h1>You have: {numFrogs.toString()} frogs</h1>
          </>
        ) : (
          <h1></h1>
        )}
      </div>

      <div id="pod-issuer-box">
        {verifyStatus ? <IssuePOD numFrogs={numFrogs}></IssuePOD> : <div></div>}
      </div>
    </div>
  );
}
