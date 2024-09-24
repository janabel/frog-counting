// import { SerializedPCD } from "@pcd/pcd-types";
// import { ZupassFolderContent } from "@pcd/zupass-client";
import { React, ReactNode, useMemo, useState } from "react";
import { TryIt } from "../components/TryIt";
// import { useEmbeddedZupass } from "../hooks/useEmbeddedZupass";
// import { ZUPASS_URL } from "../constants";
// import { parseFrog } from "../utils/parseData";
import { createProof } from "../utils/runSonobe";
import frogData from "../assets/frog_inputs_4.json";

export function Prover(): ReactNode {
  // const { z, connected } = useEmbeddedZupass();
  // const [list, setList] = useState<ZupassFolderContent[]>([]);

  interface Frog {
    frogId: string;
    biome: string;
    rarity: string;
    temperament: string;
    jump: string;
    speed: string;
    intelligence: string;
    beauty: string;
    timestampSigned: string;
    ownerSemaphoreId: string;
    frogSignerPubkeyAx: string;
    frogSignerPubkeyAy: string;
    semaphoreIdentityTrapdoor: string;
    semaphoreIdentityNullifier: string;
    watermark: string;
    frogSignatureR8x: string;
    frogSignatureR8y: string;
    frogSignatureS: string;
    externalNullifier: string;
    reservedField1: string;
    reservedField2: string;
    reservedField3: string;
  }

  async function readData() {
    const frogsArray: Frog[] = Object.values(frogData);
    console.log("frogsArray", frogsArray);
    createProof(frogsArray);
  }

  return (
    <div>
      <div className="prose">
        <div>
          <TryIt onClick={readData} label="generate inputs + prove" />
        </div>
      </div>
    </div>
  );
}
