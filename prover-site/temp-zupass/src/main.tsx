import { connect, Zapp } from "@parcnet-js/app-connector";

// The details of our Zapp
const zapp: Zapp = {
  name: "Frog Counting Zapp",
  permissions: {
    REQUEST_PROOF: { collections: ["FrogCrypto"] },
    SIGN_POD: {},
    READ_POD: { collections: ["FrogCrypto"] },
    INSERT_POD: { collections: ["FrogCrypto"] },
    DELETE_POD: { collections: ["FrogCrypto"] },
    READ_PUBLIC_IDENTIFIERS: {},
  },
};

// The HTML element to host the <iframe>
const element = document.getElementById("parcnet-app-connector") as HTMLElement;

// The URL to Zupass
const clientUrl = "https://zupass.org";
console.log("fine so far");

// Connect!
const z = await connect(zapp, element, clientUrl);

const queryResult = await z.pod.collection("FrogCrypto").query({
  entries: {
    frogID: { type: "string" },
  },
});

console.log("testing queryResult: ", queryResult);
