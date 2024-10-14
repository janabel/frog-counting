// import { useEmbeddedZupass } from "../hooks/useEmbeddedZupass";
// import { ArgumentTypeName } from "@pcd/pcd-types";
// import { SerializedPCD } from "@pcd/pcd-types";
import { PODStringValue } from "@pcd/pod";
import { POD, PODEntries } from "@pcd/pod";
import * as p from "@parcnet-js/podspec";
import frogWhispererImg from "../assets/frogwhisperer.png";
import { Spinner } from "@chakra-ui/react";
import { useEffect, useState } from "react";
import { useEmbeddedZupass } from "../hooks/useEmbeddedZupass";
import { AddToZupass } from "./AddToZupass";
// import { ZupassAPI } from "@pcd/zupass-client";

// const pcdPod = await import('@pcd/pod');
// import { Identity } from "@semaphore-protocol/identity";
// import { v4 as uuid } from "uuid";

// interface issuePODProps {
//   verifier_status: boolean;
// }
// export function IssuePOD({ verifier_status }: issuePODProps) {

export function IssuePOD() {
  const { z, connected } = useEmbeddedZupass();
  const [pod, setPOD] = useState<POD>();
  const [loading, setLoading] = useState(true);
  const [semaphoreIDCommitment, setIDCommit] = useState(0n);
  const [error, setError] = useState<unknown>(null);

  const generatePOD = async () => {
    try {
      // first, fetch user semaphore id
      const semaphoreIDCommitment = await z.identity.getSemaphoreV3Commitment();
      setIDCommit(semaphoreIDCommitment); // Update state with fetched data
      console.log("semaphoreIDCommitment", semaphoreIDCommitment);

      // then, construct rest of POD
      // if all else successful and loading = false (i.e. successfully got user ID), proceed to generate full POD
      // get public signals from user input to verifier
      // const public_signals_val = (
      //   document.getElementById("public-signals-input") as HTMLInputElement
      // )?.value;
      const public_signals_val = "hi";

      const frogWhispererEntries: PODEntries = {
        public_signals: { type: "string", value: public_signals_val },
        zupass_display: { type: "string", value: "collectable" },
        zupass_image_url: {
          type: "string",
          value:
            "https://upload.wikimedia.org/wikipedia/commons/6/64/Zhuangzi.gif",
        },
        zupass_title: { type: "string", value: "frog whisperer" },
        zupass_description: {
          type: "string",
          value: "gotta catch 'em all",
        },
        owner: {
          type: "string",
          value: semaphoreIDCommitment.toString(),
        },
      };

      const frogWhispererPOD = await z.pod.sign(frogWhispererEntries);
      setPOD(frogWhispererPOD);

      setLoading(false);
    } catch (err: unknown) {
      setError(err);
      setLoading(false);
    }
  };

  useEffect(() => {
    if (loading) {
      generatePOD();
    } else {
      return;
    }
  }, [loading]);

  if (!connected) {
    return (
      <div>
        <p className="mb-4">Zupass disconnected, please reload page.</p>
      </div>
    );
  }

  if (loading) {
    return (
      <div>
        <p className="mb-4">Generating POD...</p>
        <Spinner size="xl" />
      </div>
    );
  }

  if (error) {
    return <>Error while fetching user ID: {error}</>;
  }

  // otherwise, POD is ready to render
  return (
    <div className="flex flex-col gap-4 my-4">
      <div>
        <h1 className="text-xl font-bold mb-2">
          ‧₊˚Congratulations, you are now a Frog Whisperer ‧₊˚
        </h1>
        <img
          src={frogWhispererImg}
          alt="Frog Whisperer Image"
          style={{ width: "300px", height: "auto" }}
        />
        {/* <pre>[POD displayed here]</pre> */}
      </div>
      {pod ? <AddToZupass pod={pod}></AddToZupass> : <></>}
    </div>
  );
}
