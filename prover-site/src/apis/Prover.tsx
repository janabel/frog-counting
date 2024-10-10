import { SerializedPCD } from "@pcd/pcd-types";
import { PODStringValue } from "@pcd/pod";
import { POD, PODEntries } from "@pcd/pod";
import * as p from "@parcnet-js/podspec";
// import { ZupassFolderContent } from "@pcd/zupass-client";
import { React, ReactNode, useMemo, useState } from "react";
import { TryIt } from "../components/TryIt";
import { useEmbeddedZupass } from "../hooks/useEmbeddedZupass";
import { ZUPASS_URL } from "../constants";
import { parseFrog } from "../utils/parseData";
import { createProof } from "../utils/runSonobe";

export function Prover(): ReactNode {
  const { z, connected } = useEmbeddedZupass();
  // const [list, setList] = useState<ZupassFolderContent[]>([]);

  // console.log(p.PodSpec)

  async function getID() {
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

    const rootList = await z.pod.collection("FrogCrypto").query(
      p.pod({
        entries: {
          frogID: { type: "string" },
        },
      })
    );

    console.log("rootList", rootList);
    // return rootList;

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

    // TODO: get semaphoreID pod with from new parcnetwrapper types
    const semaphoreIdentityID = (
      rootList.find(
        (i) => i.type === "pcd" && i.pcdType === "semaphore-identity-pcd"
      ) as { id: string }
    )?.id;
    if (semaphoreIdentityID) {
      const identityPCD = await z.fs.get(semaphoreIdentityID);
      const [trapdoor, nullifier] = JSON.parse(
        JSON.parse(identityPCD.pcd).identity
      );
      console.log("trappdoor, nullifier", { trapdoor, nullifier });
      return [trapdoor, nullifier];
    }
  }

  async function readData() {
    const result = await getID();
    console.log("result", result);
    const [semaphoreIDtrapdoor, semaphoreIDnullifier] = result;

    const frogPCDList = await z.fs.list("FrogCrypto");
    // maps each frogPCD in the array to a parsed version
    const promises = frogPCDList.map(async (frogPCD: Object) => {
      const frog = await z.fs.get(frogPCD.id);
      console.log("frog", frog);
      const result = await parseFrog(
        frog,
        semaphoreIDtrapdoor,
        semaphoreIDnullifier
      );
      return result;
    });

    const circuitInputs = await Promise.all(promises);

    // adding indices for frogs to be able to maintain an order (hashmap passed into sonobe has none on its own, but incorrect order => folding fails)
    const transformedCircuitInputs: { [key: string]: { [key: string]: any } } =
      {};
    circuitInputs.forEach((item, index) => {
      transformedCircuitInputs[(index + 1).toString()] = item; // Adding 1 to make keys start from 1
    });

    console.log(transformedCircuitInputs);

    // console.log("circuitInputs", circuitInputs);
    setList([transformedCircuitInputs]);
    console.log(
      "stringify of circuit inputs",
      JSON.stringify(transformedCircuitInputs)
    );
    // console.log(transformedCircuitInputs);
    createProof(circuitInputs);
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
