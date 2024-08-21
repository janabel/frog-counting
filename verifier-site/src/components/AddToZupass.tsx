import { SerializedPCD } from "@pcd/pcd-types";
// import { ZupassFolderContent } from "@pcd/zupass-client";
import { ReactNode, useMemo, useState } from "react";
// import { TryIt } from "./TryIt";
import { useEmbeddedZupass } from "../hooks/useEmbeddedZupass";
import { ZUPASS_URL } from "../constants";
import { POD } from "@pcd/pod";
// import { v4 as uuid } from "uuid";
import { PODPCD, PODPCDPackage } from "@pcd/pod-pcd";

export interface AddToZupassProps {
  pod: POD;
}

// pcd =
// type
// pcd: {id, other stuff (maybe pcds)}

export function AddToZupass({ pod }: AddToZupassProps): ReactNode {
  const { z, connected } = useEmbeddedZupass();
  // const [list, setList] = useState<ZupassFolderContent[]>([]);
  // const [pcd, setPCD] = useState<SerializedPCD>();
  const [pcdAdded, setPCDAdded] = useState(false);
  const zupassUrl = useMemo(() => {
    return localStorage.getItem("zupassUrl") || ZUPASS_URL;
  }, []);

  console.log("POD content", pod.content);
  console.log("POD signature", pod.signature);
  console.log("POD signerPublicKey", pod.signerPublicKey);
  console.log("POD (content)ID", pod.contentID);
  console.log("pod object type", typeof pod);

  // time to convert POD to PCD to put into zupass...
  const podPCD = new PODPCD(pod.contentID.toString(), pod);
  // type: string;
  //   claim: PODPCDClaim;
  //   proof: PODPCDProof;
  //   id: string;
  console.log("podPCD claim", podPCD.claim);

  // const newPOD = new PODPCD(uuid(), pod);

  let serializedPodPCD: SerializedPCD;
  PODPCDPackage.serialize(podPCD).then((result) => {
    serializedPodPCD = result;
  });

  return !connected ? null : (
    <div className="flex flex-col gap-4 my-4">
      <div>
        <h1 className="text-xl font-bold mb-2">
          Add your Frog Master PCD to Zupass
        </h1>

        <button
          className="btn btn-primary"
          onClick={async () => {
            try {
              await z.fs.put("/Testing", serializedPodPCD);
              setPCDAdded(true);
            } catch (e) {
              console.log(e);
            }
          }}
        >
          Add PCD
        </button>
        {/* <TryIt
          onClick={async () => {
            try {
              await z.fs.put("/Testing", serializedPodPCD);
              setPCDAdded(true);
            } catch (e) {
              console.log(e);
            }
          }}
          label="Add PCD"
        /> */}
      </div>
      <div>
        {pcdAdded && (
          <p>
            PCD added!{" "}
            <a
              href={zupassUrl}
              target="_blank"
              style={{ color: "green", textDecoration: "underline" }}
            >
              View in Zupass
            </a>
            .
          </p>
        )}
      </div>
    </div>
  );
}
