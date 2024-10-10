import { SerializedPCD } from "@pcd/pcd-types";
import { PODStringValue } from "@pcd/pod";
import { POD, PODEntries } from "@pcd/pod";
import * as p from "@parcnet-js/podspec";
// import { ZupassFolderContent } from "@pcd/zupass-client"; // OUTDATED!
import { React, ReactNode, useMemo, useState } from "react";
import { TryIt } from "../components/TryIt";
import { useEmbeddedZupass } from "../hooks/useEmbeddedZupass";
import { ZUPASS_URL } from "../constants";
import { parseFrog, parseFrogPOD } from "../utils/parseData";
import { createProof } from "../utils/runSonobe";
// import test frogs
import { testFrog1, testFrog2, testFrog3 } from "../testfrogs";

export function Prover(): ReactNode {
  const { z, connected } = useEmbeddedZupass();
  // const [list, setList] = useState<ZupassFolderContent[]>([]);

  async function makeTestFrogs() {
    // add test frogs to Collections/FrogCryptoTest folder while we wait for zupass team to migrate FrogCrypto over to Collections

    // console.log("Sample entries", sampleEntries);
    const signedTestFrog1POD = await z.pod.sign(testFrog1);
    const signedTestFrog2POD = await z.pod.sign(testFrog2);
    const signedTestFrog3POD = await z.pod.sign(testFrog3);

    console.log("signedTestFrog1POD", signedTestFrog1POD);
    console.log("signedTestFrog2POD", signedTestFrog2POD);
    console.log("signedTestFrog3POD", signedTestFrog3POD);

    await z.pod.collection("FrogCryptoTest").insert(signedTestFrog1POD);
    await z.pod.collection("FrogCryptoTest").insert(signedTestFrog2POD);
    await z.pod.collection("FrogCryptoTest").insert(signedTestFrog3POD);

    console.log(
      "should have added testFrog1, testFrog2, testFrog3 to folder Collections/FrogCryptoTest"
    );

    return;
  }

  async function getID() {
    const semaphoreIDCommitment = await z.identity.getSemaphoreV4Commitment();
    return semaphoreIDCommitment;
  }

  async function readData() {
    // first make test frogs to insert to FrogCryptoTest
    await makeTestFrogs();
    console.log("made test frogs!");

    // then get semaphore ID commitment
    const semaphoreIDCommitment = await getID();
    console.log("semaphoreIDCommitment", semaphoreIDCommitment);
    // const semaphoreIDCommitment = result;

    const frogPODList = await z.pod.collection("FrogCryptoTest").query(
      // lookin for them frogs
      p.pod({
        entries: {
          frogId: { type: "string" },
        },
      })
    );

    console.log("frogPCDList", frogPODList);

    const promises = frogPODList.map(async (frogPOD: object) => {
      console.log("frogPOD", frogPOD);
      const result = await parseFrogPOD(frogPOD, semaphoreIDCommitment);
      console.log("parsedFrogPOD: ", result);
      return result;
    });

    const circuitInputs = await Promise.all(promises);
    console.log("circuitInputs", circuitInputs);

    // maps each frogPCD in the array to a parsed version
    // const promises = frogPCDList.map(async (frogPCD: object) => {
    //   console.log("frogPCD", frogPCD);
    // const frog = await z.fs.get(frogPCD.id);
    // console.log("frog", frog);
    // const result = await parseFrog(frog, semaphoreIDCommitment);
    // return result;
    // });

    // const circuitInputs = await Promise.all(promises);
    // console.log("circuitInputs", circuitInputs);

    // adding indices for frogs to be able to maintain an order (hashmap passed into sonobe has none on its own, but incorrect order => folding fails)
    // const transformedCircuitInputs: { [key: string]: { [key: string]: any } } =
    //   {};
    // circuitInputs.forEach((item, index) => {
    //   transformedCircuitInputs[(index + 1).toString()] = item; // Adding 1 to make keys start from 1
    // });

    // console.log("circuitInputs", circuitInputs);
    // setList([transformedCircuitInputs]);
    // console.log(
    //   "stringify of circuit inputs",
    //   JSON.stringify(transformedCircuitInputs)
    // );
    // console.log(transformedCircuitInputs);
    // createProof(circuitInputs);
  }

  return !connected ? null : (
    <div>
      <div className="prose">
        <div>
          <TryIt onClick={readData} label="Generate Circuit Inputs + Prove" />
          {/* {list.length > 0 && (
            <pre className="whitespace-pre-wrap">
              {JSON.stringify(list, null, 2)}
            </pre>
          )} */}
        </div>
      </div>
    </div>
  );
}

// // TODO: get semaphoreID pod with from new parcnetwrapper types
// const semaphoreIdentityID = (
//   rootList.find(
//     (i) => i.type === "pcd" && i.pcdType === "semaphore-identity-pcd"
//   ) as { id: string }
// )?.id;
// if (semaphoreIdentityID) {
//   const identityPCD = await z.fs.get(semaphoreIdentityID);
//   const [trapdoor, nullifier] = JSON.parse(
//     JSON.parse(identityPCD.pcd).identity
//   );
//   console.log("trappdoor, nullifier", { trapdoor, nullifier });
//   return [trapdoor, nullifier];
// }

// console.log(
//   "z.pod.collection(FrogWhisperer)",
//   z.pod.collection("FrogWhisperer")
// ); // returns a parcentPODcollection wrapper, which also implements a query function

// trying to query for pods...

// testing with FrogWhisperer Folder
// const validOwners = [{ type: "string", value: "0" }] as PODStringValue[];
// owner: { type: "string"},
// public_signals: { type: "string" },
// someNumber: { type: "int" },
// zupass_display: { type: "string" },
// zupass_image_url: { type: "string" },
// zupass_title: { type: "string" },
// zupass_description: { type: "string" },

// // trying to add a pod to folder

// const sampleEntries: PODEntries = {
//   entry1: { type: "string", value: "hi1" },
//   entry2: { type: "string", value: "hi2" },
//   zupass_title: {
//     type: "string",
//     value: "testing add from parcnet-js praying",
//   },
//   zupass_display: { type: "string", value: "collectable" },
//   zupass_image_url: {
//     type: "string",
//     value:
//       "https://upload.wikimedia.org/wikipedia/commons/6/64/Zhuangzi.gif",
//   },
//   zupass_description: {
//     type: "string",
//     value: "testing...",
//   },
// };
// console.log("Sample entries", sampleEntries);
// const signedPOD = await z.pod.sign(sampleEntries);
// console.log("signedPOD", signedPOD);
// await z.pod.collection("FrogWhisperer").insert(signedPOD);
// console.log("should have added signedPOD to folder FrogWhisperer");
