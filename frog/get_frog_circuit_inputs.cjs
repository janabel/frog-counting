import {
  generateSnarkMessageHash,
  hexToBigInt,
  fromHexString,
} from "@pcd/util";
import { buildEddsa } from "circomlibjs";
import { groth16 } from "snarkjs";
import { Buffer } from "buffer";

let proof = undefined;
let publicSignals = undefined;

const vkeyResponse = await fetch("./frog_vkey.json");
const vkey = await vkeyResponse.json();
const STATIC_ZK_EDDSA_FROG_PCD_NULLIFIER = generateSnarkMessageHash(
  "hard-coded-zk-eddsa-frog-pcd-nullifier"
);

// Custom assert that logs to console?
function assert(condition, message = "Assertion failed") {
  console.log(condition);
  if (!condition) {
    throw new Error(message);
  }
}

const JBEL_TRAPDOOR =
  "19203180509052113016252601264864235852564023528134367070099013180198396222";
const JBEL_NULLIFIER =
  "46501085880889723880043204259130159126257178560019589221443961884550616786";

async function parseFrog(rawFrog, semaphoreIDtrapdoor, semaphoreIDnullifier) {
  /* INPUT = {
      "frogId": "10",
      "timestampSigned": "1723063971239",
      "ownerSemaphoreId": "9964141043217120936664326897183667118469716023855732146334024524079553329018",
      "frogSignerPubkeyAx": "6827523554590803092735941342538027861463307969735104848636744652918854385131",
      "frogSignerPubkeyAy": "19079678029343997910757768128548387074703138451525650455405633694648878915541",
      "semaphoreIdentityTrapdoor": "135040283343710365777958365424694852760089427911973547434460426204380274744",
      "semaphoreIdentityNullifier": "358655312360435269311557940631516683613039221013826685666349061378483316589",
      "watermark": 2718,
      "frogSignatureR8x": "1482350313869864254042595459421095897218687816166241224483874238825079857068",
      "frogSignatureR8y": "21443280299859662584655395271110089155773803041593918291203552153143944893901",
      "frogSignatureS": "1391256727295516554759691112683783404841502861038527717248540264088174477546",
      "externalNullifier": "10661416524110617647338817740993999665252234336167220367090184441007783393",
      "biome": "3",
      "rarity": "1",
      "temperament": "11",
      "jump": "1",
      "speed": "1",
      "intelligence": "0",
      "beauty": "3",
      "reservedField1": "0",
      "reservedField2": "0",
      "reservedField3": "0"
    } */

  console.log("semaphoreIDtrapdoor", semaphoreIDtrapdoor);
  const rawJSON = JSON.parse(rawFrog);

  assert(rawJSON.type == "eddsa-frog-pcd");
  const frogPCD = rawJSON.pcd;
  const frogJSON = JSON.parse(frogPCD);
  const eddsaPCD = frogJSON.eddsaPCD;
  const frogData = frogJSON.data;
  const { name, description, imageUrl, ...frogInfo } = frogData;

  const pcdJSON = JSON.parse(eddsaPCD.pcd);

  assert(pcdJSON.type == "eddsa-pcd");
  const signature = pcdJSON.proof.signature;

  const eddsa = await buildEddsa();
  const rawSig = eddsa.unpackSignature(fromHexString(signature));
  const frogSignatureR8x = eddsa.F.toObject(rawSig.R8[0]).toString();
  const frogSignatureR8y = eddsa.F.toObject(rawSig.R8[1]).toString();
  const frogSignatureS = rawSig.S.toString();

  return {
    ...frogInfo,
    frogSignerPubkeyAx: hexToBigInt(pcdJSON.claim.publicKey[0]).toString(),
    frogSignerPubkeyAy: hexToBigInt(pcdJSON.claim.publicKey[1]).toString(),
    semaphoreIdentityTrapdoor: semaphoreIDtrapdoor,
    semaphoreIdentityNullifier: semaphoreIDnullifier,
    watermark: "2718", // ?
    frogSignatureR8x: frogSignatureR8x,
    frogSignatureR8y: frogSignatureR8y,
    frogSignatureS: frogSignatureS,
    externalNullifier: STATIC_ZK_EDDSA_FROG_PCD_NULLIFIER,
    reservedField1: "0",
    reservedField2: "0",
    reservedField3: "0",
  };
}

const jbelserializedFrog =
  '{"id":"40e306a4-c2bf-4c2f-bad1-186475118041","eddsaPCD":{"type":"eddsa-pcd","pcd":"{\\"type\\":\\"eddsa-pcd\\",\\"id\\":\\"9ad36f33-ae49-42e4-85d2-fa4f1675a81c\\",\\"claim\\":{\\"message\\":[\\"1a\\",\\"3\\",\\"1\\",\\"a\\",\\"6\\",\\"4\\",\\"6\\",\\"6\\",\\"1912ea446b1\\",\\"3000477e9507331b8e73fb6d3b3b705e22b02021ff40c19965c5b9dc82a8ca89\\",\\"0\\",\\"0\\",\\"0\\"],\\"publicKey\\":[\\"0f183dcba06341a4549d78c3f8ca0060a9d6aca795103cb6957d1e2973b5fdeb\\",\\"2a2eb70efeebb5facca2f3668ca5642513be542bab285055ccdcbc18cc125fd5\\"]},\\"proof\\":{\\"signature\\":\\"8995c19660f59f320dfcdb4584736081aa3a89da9499bec5854e431937d0540930e1d1cb61db826e1a1a9b1a938ab016543ba6809f9a08b1dd4a56b71701ca04\\"}}"},"data":{"name":"Paedophryne Amauensis","description":"Paedophryne amauensis holds the title of the world\'s smallest vertebrate, with adults measuring only about 7.7 millimeters in length. These frogs inhabit the leaf litter of the rainforests in Papua New Guinea, where they primarily feed on tiny arthropods and remain well-camouflaged among the forest floor debris.","imageUrl":"https://api.zupass.org/frogcrypto/images/fab1ba2d-f81d-4591-8d54-0b4e38dd5285","frogId":26,"biome":3,"rarity":1,"temperament":10,"jump":6,"speed":4,"intelligence":6,"beauty":6,"timestampSigned":1723064403633,"ownerSemaphoreId":"21711510168635182051334357427785411794318044815986410056285364391413272857225"}}';
console.log(parseFrog(jbelserializedFrog, JBEL_NULLIFIER, JBEL_TRAPDOOR));
