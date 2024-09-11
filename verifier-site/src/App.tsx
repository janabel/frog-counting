import { EmbeddedZupassProvider } from "./hooks/useEmbeddedZupass";
import { Navbar } from "./components/Navbar";
import { VerifyRust } from "./components/VerifyRust";
// import { GPC } from "./apis/GPC";
// import { FileSystem } from "./apis/FileSystem";
import { ZUPASS_URL } from "./constants";
// import { Identity } from "./apis/Identity";
import { ChakraProvider } from "@chakra-ui/react";
import { Header } from "./components/Header";
// import { LuAlignVerticalJustifyCenter } from "react-icons/lu";

const zapp = {
  name: "test-client",
  permissions: ["read", "write"],
};

function App() {
  const zupassUrl = localStorage.getItem("zupassUrl") || ZUPASS_URL;

  return (
    <ChakraProvider>
      <EmbeddedZupassProvider zapp={zapp} zupassUrl={zupassUrl}>
        <Navbar />
        <div className="container mx-auto my-4 p-4">
          <Header />
          <div className="flex flex-col gap-4 my-4">
            {/* <FileSystem /> */}
            <VerifyRust />
            {/* <GPC />
            <Identity /> */}
          </div>
        </div>
      </EmbeddedZupassProvider>
    </ChakraProvider>
  );
}

export default App;
