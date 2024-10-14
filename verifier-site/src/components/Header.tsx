import { Spinner } from "@chakra-ui/react";
import { useEmbeddedZupass } from "../hooks/useEmbeddedZupass";
// import { VerifyRust } from "../apis/VerifyRust";

export function Header() {
  const { connected } = useEmbeddedZupass();
  return (
    <>
      {connected && <></>}
      {!connected && (
        <div>
          <p className="mb-4">Connecting to Zupass client...</p>
          <Spinner size="xl" />
        </div>
      )}
    </>
  );
}
