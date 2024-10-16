import React from "react";
import { IssuePOD } from "../components/IssuePOD.js";
import { useState } from "react";
import { Spinner } from "@chakra-ui/react";
import init, { verifyRust } from "../../sonobe-rust/pkg/sonobe_rust.js";
import { useEmbeddedZupass } from "../hooks/useEmbeddedZupass.js";

async function readSerializedData(path: string) {
  const file_path = path;
  const response = await fetch(file_path);
  const bytes = await response.arrayBuffer();
  const res = new Uint8Array(bytes);
  // console.log("result from path " + path, res);
  return res;
}

export function VerifyRust() {
  const { z, connected } = useEmbeddedZupass();
  const [fileData, setFileData] = useState<Uint8Array>(new Uint8Array([]));
  const [verifying, setVerifying] = useState(false);
  const [verifyStatus, setVerifyStatus] = useState(false);
  const [numFrogs, setNumFrogs] = useState(0n);

  console.log("typeof z", typeof z);

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
    setVerifying(true);
    console.log("set verifying to true....");

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
    <>
      {connected ? (
        <div className="flex flex-col gap-4 my-4">
          <h1 className="text-xl font-bold mb-2">𓆏 Verify your proof 𓆏</h1>
          <p>
            Verify your frog-counting proof and get your Frog Whisperer POD
            here!
          </p>
          <input type="file" onChange={handleFileUpload} accept=".bin" />
          <div>
            <button className="btn btn-primary" onClick={verify}>
              Verify Proof
            </button>
          </div>
          <div>
            {verifying ? (
              <>
                {verifyStatus ? (
                  <>
                    <p>Proof was verified!</p>
                    <p>You have: {numFrogs.toString()} frogs</p>
                    <div id="pod-issuer-box">
                      <IssuePOD numFrogs={numFrogs}></IssuePOD>{" "}
                      {/* defer checking number of frogs to IssuePOD component*/}
                    </div>
                  </>
                ) : (
                  <h1>
                    <p className="mb-4">Verifying proof...</p>
                    <Spinner size="xl" />
                  </h1>
                )}
              </>
            ) : (
              <></>
            )}
          </div>
        </div>
      ) : (
        <></>
      )}
    </>
  );
}
