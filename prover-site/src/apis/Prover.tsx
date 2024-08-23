import { SerializedPCD } from "@pcd/pcd-types";
import { ZupassFolderContent } from "@pcd/zupass-client";
import { React, ReactNode, useMemo, useState } from "react";
import { TryIt } from "../components/TryIt";
import { useEmbeddedZupass } from "../hooks/useEmbeddedZupass";
import { ZUPASS_URL } from "../constants";
import { parseFrog } from "../utils/parseData";
import { createProof } from "../utils/runSonobe";

export function Prover(): ReactNode {
  const { z, connected } = useEmbeddedZupass();
  const [list, setList] = useState<ZupassFolderContent[]>([]);
  
  async function getID() {
    const rootList = await z.fs.list("/");
    const semaphoreIdentityID = (
      rootList.find(
        (i) =>
          i.type === "pcd" && i.pcdType === "semaphore-identity-pcd"
      ) as { id: string }
    )?.id;
    if (semaphoreIdentityID) {
        const identityPCD = await z.fs.get(semaphoreIdentityID);
        const [trapdoor, nullifier] = JSON.parse(
          JSON.parse(identityPCD.pcd).identity
        );
        console.log({ trapdoor, nullifier });
        return [trapdoor, nullifier];
    }
  }

  async function readData() {
    const result = await getID();
    const [semaphoreIDtrapdoor, semaphoreIDnullifier] = result;

    const frogPCDList = await z.fs.list("FrogCrypto");
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
    console.log("circuitInputs", circuitInputs);
    setList(circuitInputs);
    createProof(circuitInputs);
  }

  return !connected ? null : (
  <div>
    <div className="prose">
      <div>
        <TryIt onClick={readData} label="Generate Circuit Inputs" />
        {list.length > 0 && (
          <pre className="whitespace-pre-wrap">
            {JSON.stringify(list, null, 2)}
          </pre>
        )}
      </div>
    </div>
  </div>
  );
}
