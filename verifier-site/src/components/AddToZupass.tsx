import { SerializedPCD } from "@pcd/pcd-types";
import { POD } from "@pcd/pod";
// import { ZupassFolderContent } from "@pcd/zupass-client";
import { ReactNode, useMemo, useState } from "react";
// import { TryIt } from "./TryIt";
import { useEmbeddedZupass } from "../hooks/useEmbeddedZupass";
import { ZUPASS_URL } from "../constants";

export interface AddToZupassProps {
  pod: POD;
}

export function AddToZupass({ pod }: AddToZupassProps): ReactNode {
  const { z, connected } = useEmbeddedZupass();
  // const [list, setList] = useState<ZupassFolderContent[]>([]);
  // const [pcd, setPCD] = useState<SerializedPCD>();
  const [pcdAdded, setPCDAdded] = useState(false);
  const zupassUrl = useMemo(() => {
    return localStorage.getItem("zupassUrl") || ZUPASS_URL;
  }, []);

  console.log("frogwhisperer pod", pod);

  return !connected ? null : (
    <div className="flex flex-col gap-4 my-4">
      <div>
        <h1 className="text-xl font-bold mb-2">
          Add your Frog Whisperer POD to Zupass
        </h1>

        <button
          className="btn btn-primary"
          onClick={async () => {
            try {
              await z.pod.collection("FrogWhisperer").insert(pod);
              // await z.fs.put("/FrogWhisperer", serializedPodPCD);
              setPCDAdded(true);
            } catch (e) {
              console.log(e);
            }
          }}
        >
          Add POD
        </button>
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
