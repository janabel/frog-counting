import { EmbeddedZupassProvider } from "./hooks/useEmbeddedZupass";
import { Navbar } from "./components/Navbar";
import { Prover } from "./apis/Prover";
import { ZUPASS_URL } from "./constants";
import { ChakraProvider } from "@chakra-ui/react";
import { Header } from "./components/Header";
import { Zapp } from "@parcnet-js/app-connector";

const zapp: Zapp = {
  name: "froge",
  permissions: {
    REQUEST_PROOF: { collections: ["FrogCrypto", "FrogWhisperer", "/"] },
    SIGN_POD: {},
    READ_POD: { collections: ["FrogCrypto", "FrogWhisperer", "/"] },
    INSERT_POD: { collections: ["FrogCrypto", "FrogWhisperer", "/"] },
    DELETE_POD: { collections: ["FrogCrypto", "FrogWhisperer", "/"] },
    READ_PUBLIC_IDENTIFIERS: {},
  },
};

console.log("testing zapp setup", zapp);

function App() {
  const zupassUrl = localStorage.getItem("zupassUrl") || ZUPASS_URL;

  return (
    <ChakraProvider>
      <EmbeddedZupassProvider zapp={zapp} zupassUrl={zupassUrl}>
        <Navbar />
        <div className="container mx-auto my-4 p-4">
          <Header />
          <div className="flex flex-col gap-4 my-4">
            <Prover />
          </div>
        </div>
      </EmbeddedZupassProvider>
    </ChakraProvider>
  );
}

export default App;
