import { EmbeddedZupassProvider } from "./hooks/useEmbeddedZupass";
import { Navbar } from "./components/Navbar";
import { Prover } from "./apis/Prover";
import { ZUPASS_URL } from "./constants";
import { ChakraProvider } from "@chakra-ui/react";
import { Header } from "./components/Header";
import { useEffect, useState } from "react";
import init, { greet } from '../public/pkg/greet_rust_wasm';

const zapp = {
  name: "test-client",
  permissions: ["read", "write"],
};

async function loadWasm() {
  await init();
  greet("hi");
}

function App() {
  const zupassUrl = localStorage.getItem("zupassUrl") || ZUPASS_URL;

  loadWasm();

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
