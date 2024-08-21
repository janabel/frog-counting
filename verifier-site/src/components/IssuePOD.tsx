// import { useEmbeddedZupass } from "../hooks/useEmbeddedZupass";
// import { ArgumentTypeName } from "@pcd/pcd-types";
// import { SerializedPCD } from "@pcd/pcd-types";
import frogMasterImg from "../assets/frogmaster.png";
import { Spinner } from "@chakra-ui/react";
import { useEffect, useState } from "react";
import {
  POD,
  //   PODContent,
  PODEntries,
  //   deserializePODEntries,
  //   podEntriesFromSimplifiedJSON,
  //   podEntriesToSimplifiedJSON,
  //   serializePODEntries,
} from "@pcd/pod";
import { useEmbeddedZupass } from "../hooks/useEmbeddedZupass";
import { ZupassAPI } from "@pcd/zupass-client";
import { AddToZupass } from "./AddToZupass";

// const pcdPod = await import('@pcd/pod');
// import { Identity } from "@semaphore-protocol/identity";
// import { v4 as uuid } from "uuid";

// interface issuePODProps {
//   verifier_status: boolean;
// }
// export function IssuePOD({ verifier_status }: issuePODProps) {

export function IssuePOD() {
  const { z, connected } = useEmbeddedZupass() as {
    z: ZupassAPI;
    connected: boolean;
  };
  const [pod, setPOD] = useState<POD>();
  const [loading, setLoading] = useState(true);
  const [semaphoreIDcommit, setIDCommit] = useState(0n);
  const [error, setError] = useState<unknown>(null);

  const generatePOD = async () => {
    try {
      // first, fetch user semaphore id
      const semaphoreIDCommitment = await z.identity.getIdentityCommitment();
      setIDCommit(semaphoreIDCommitment); // Update state with fetched data
      console.log("semaphoreIDCommitment", semaphoreIDCommitment);

      // then, construct rest of POD
      // if all else successful and loading = false (i.e. successfully got user ID), proceed to generate full POD
      // get public signals from user input to verifier
      const public_signals_val = (
        document.getElementById("public-signals-input") as HTMLInputElement
      )?.value;

      const sampleEntries: PODEntries = {
        public_signals: { type: "string", value: public_signals_val },
        someNumber: { type: "int", value: -123n },
        zupass_display: { type: "string", value: "collectable" },
        zupass_image_url: {
          type: "string",
          value:
            // "https://upload.wikimedia.org/wikipedia/commons/a/a7/Perereca-macaco_-_Phyllomedusa_rohdei.jpg",
            "https://upload.wikimedia.org/wikipedia/commons/6/64/Zhuangzi.gif",
        },
        zupass_title: { type: "string", value: "frog master" },
        zupass_description: {
          type: "string",
          value: "gotta catch 'em all",
        },
        owner: {
          type: "string",
          value: semaphoreIDcommit.toString(),
        },
      };
      console.log("Sample entries", sampleEntries);
      // PODs are signed using EdDSA signatures, which are easy to check in a
      // ZK circuit.  Our private keys can be any 32 bytes encoded as Base64 or hex.
      const privateKey = "ASNFZ4mrze8BI0VniavN7wEjRWeJq83vASNFZ4mrze8"; // dummy private key for our app, will use later.

      // Signing a POD is usually performed in a single step like this.  No need
      // to go through the PODContent class.
      setPOD(POD.sign(sampleEntries, privateKey));

      setLoading(false);
    } catch (err: unknown) {
      setError(err); // Handle errors
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
          ‧₊˚Congratulations, you are now a Frog Master ‧₊˚
        </h1>
        <img
          src={frogMasterImg}
          alt="Frog Master Image"
          style={{ width: "300px", height: "auto" }}
        />
        {/* <pre>[POD displayed here]</pre> */}
      </div>
      {pod ? <AddToZupass pod={pod}></AddToZupass> : <></>}
    </div>
  );
}
