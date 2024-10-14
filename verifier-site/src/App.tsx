import { EmbeddedZupassProvider } from "./hooks/useEmbeddedZupass";
import { Navbar } from "./components/Navbar";
import { VerifyRust } from "./apis/VerifyRust";
// import { GPC } from "./apis/GPC";
// import { FileSystem } from "./apis/FileSystem";
import { ZUPASS_URL } from "./constants";
// import { Identity } from "./apis/Identity";
import { ChakraProvider } from "@chakra-ui/react";
import { Header } from "./components/Header";
// import { LuAlignVerticalJustifyCenter } from "react-icons/lu";
import { Zapp } from "@parcnet-js/app-connector";

const zapp: Zapp = {
  name: "Frog Whisperer Issuer",
  permissions: {
    REQUEST_PROOF: { collections: ["FrogWhisperer", "/"] },
    SIGN_POD: {},
    READ_POD: { collections: ["FrogWhisperer", "/"] },
    INSERT_POD: { collections: ["FrogWhisperer", "/"] },
    DELETE_POD: { collections: ["FrogWhisperer", "/"] },
    READ_PUBLIC_IDENTIFIERS: {},
  },
};

function App() {
  const zupassUrl = localStorage.getItem("zupassUrl") || ZUPASS_URL;

  return (
    <ChakraProvider>
      <EmbeddedZupassProvider zapp={zapp} zupassUrl={zupassUrl}>
        <Navbar />
        <div className="container mx-auto my-4 p-4">
          <Header />
          <VerifyRust />
        </div>
      </EmbeddedZupassProvider>
    </ChakraProvider>
  );
}

export default App;
