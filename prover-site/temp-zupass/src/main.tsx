import { connect, Zapp } from "@parcnet-js/app-connector";

// The details of our Zapp
const myZapp: Zapp = {
  name: "My Zapp Name",
};

// The HTML element to host the <iframe>
const element = document.getElementById("parcnet-app-connector") as HTMLElement;

// The URL to Zupass
const clientUrl = "http://localhost:3000";

// Connect!
const z = await connect(myZapp, element, clientUrl);

const queryResult = await z.pod.query({
  frogID: { type: "string" },
});

console.log(queryResult);
