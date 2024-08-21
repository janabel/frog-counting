import { Spinner } from "@chakra-ui/react";
import { useEmbeddedZupass } from "../hooks/useEmbeddedZupass";

export function Header() {
  const { connected } = useEmbeddedZupass();
  return (
    <div>
      {connected && (
        <p>
          🐸 Verify your frog-counting proof and get your Frog Master POD here!
          🐸
        </p>
      )}
      {!connected && (
        <div>
          <p className="mb-4">Connecting to Zupass client...</p>
          <Spinner size="xl" />
        </div>
      )}
    </div>
  );
}
