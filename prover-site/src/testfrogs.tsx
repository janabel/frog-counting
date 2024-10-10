import { PODStringValue } from "@pcd/pod";
import { POD, PODEntries } from "@pcd/pod";
import * as p from "@parcnet-js/podspec";

export const testFrog1: PODEntries = {
  frogId: { type: "string", value: "6" },
  biome: { type: "string", value: "1" },
  rarity: { type: "string", value: "1" },
  temperament: { type: "string", value: "10" },
  jump: { type: "string", value: "7" },
  speed: { type: "string", value: "6" },
  intelligence: { type: "string", value: "0" },
  beauty: { type: "string", value: "4" },
  timestampSigned: { type: "string", value: "1723064143986" },
  ownerSemaphoreId: {
    type: "string",
    value:
      "16900317739984313123151401564016026184213974271747575439963283112075081788820",
  },
  frogSignerPubkeyAx: {
    type: "string",
    value:
      "6827523554590803092735941342538027861463307969735104848636744652918854385131",
  },
  frogSignerPubkeyAy: {
    type: "string",
    value:
      "19079678029343997910757768128548387074703138451525650455405633694648878915541",
  },
  //   semaphoreIdentityTrapdoor: {
  //     type: "string",
  //     value:
  //       "19203180509052113016252601264864235852564023528134367070099013180198396222",
  //   },
  //   semaphoreIdentityNullifier: {
  //     type: "string",
  //     value:
  //       "46501085880889723880043204259130159126257178560019589221443961884550616786",
  //   },
  watermark: { type: "string", value: "2718" },
  frogSignatureR8x: {
    type: "string",
    value:
      "8308345443877574455848684270861642763106914226648353437201284045749442492941",
  },
  frogSignatureR8y: {
    type: "string",
    value:
      "18311873231429368494689285463284720341339905265192055351528173378608637373108",
  },
  frogSignatureS: {
    type: "string",
    value:
      "1085776139284236921405845738599612621282582858928899460440542121727713039022",
  },
  externalNullifier: {
    type: "string",
    value:
      "10661416524110617647338817740993999665252234336167220367090184441007783393",
  },
  reservedField1: { type: "string", value: "0" },
  reservedField2: { type: "string", value: "0" },
  reservedField3: { type: "string", value: "0" },

  zupass_title: {
    type: "string",
    value: "test frog 1",
  },
  zupass_display: { type: "string", value: "collectable" },
  zupass_image_url: {
    type: "string",
    value:
      "https://upload.wikimedia.org/wikipedia/commons/e/eb/Drawing_for_beginners_%281920%29_%2814566679909%29.jpg",
  },
  zupass_description: {
    type: "string",
    value:
      "this is a test frog while we wait for the great frog(crypto) migration",
  },
};

export const testFrog2: PODEntries = {
  frogId: { type: "string", value: "41" },
  biome: { type: "string", value: "4" },
  rarity: { type: "string", value: "2" },
  temperament: { type: "string", value: "4" },
  jump: { type: "string", value: "5" },
  speed: { type: "string", value: "6" },
  intelligence: { type: "string", value: "13" },
  beauty: { type: "string", value: "3" },
  timestampSigned: { type: "string", value: "1723953310265" },
  ownerSemaphoreId: {
    type: "string",
    value:
      "16900317739984313123151401564016026184213974271747575439963283112075081788820",
  },
  frogSignerPubkeyAx: {
    type: "string",
    value:
      "6827523554590803092735941342538027861463307969735104848636744652918854385131",
  },
  frogSignerPubkeyAy: {
    type: "string",
    value:
      "19079678029343997910757768128548387074703138451525650455405633694648878915541",
  },
  //   semaphoreIdentityTrapdoor: {
  //     type: "string",
  //     value:
  //       "19203180509052113016252601264864235852564023528134367070099013180198396222",
  //   },
  //   semaphoreIdentityNullifier: {
  //     type: "string",
  //     value:
  //       "46501085880889723880043204259130159126257178560019589221443961884550616786",
  //   },
  watermark: { type: "string", value: "2718" },
  frogSignatureR8x: {
    type: "string",
    value:
      "10517044756716496621361564227181438171445537121459952442968808491636280676673",
  },
  frogSignatureR8y: {
    type: "string",
    value:
      "9661569621990978861940572967798263862315967010994900316384526316994339578370",
  },
  frogSignatureS: {
    type: "string",
    value:
      "1977133170206105455473357364957292894476300124182020214638578839779839457774",
  },
  externalNullifier: {
    type: "string",
    value:
      "10661416524110617647338817740993999665252234336167220367090184441007783393",
  },
  reservedField1: { type: "string", value: "0" },
  reservedField2: { type: "string", value: "0" },
  reservedField3: { type: "string", value: "0" },

  zupass_title: {
    type: "string",
    value: "test frog 2",
  },
  zupass_display: { type: "string", value: "collectable" },
  zupass_image_url: {
    type: "string",
    value:
      "https://upload.wikimedia.org/wikipedia/commons/e/eb/Drawing_for_beginners_%281920%29_%2814566679909%29.jpg",
  },
  zupass_description: {
    type: "string",
    value:
      "this is a test frog while we wait for the great frog(crypto) migration",
  },
};

export const testFrog3: PODEntries = {
  frogId: { type: "string", value: "39" },
  biome: { type: "string", value: "1" },
  rarity: { type: "string", value: "1" },
  temperament: { type: "string", value: "10" },
  jump: { type: "string", value: "6" },
  speed: { type: "string", value: "2" },
  intelligence: { type: "string", value: "2" },
  beauty: { type: "string", value: "0" },
  timestampSigned: { type: "string", value: "1723064107966" },
  ownerSemaphoreId: {
    type: "string",
    value:
      "16900317739984313123151401564016026184213974271747575439963283112075081788820", // jbel's own semaphore v4 ID (idcommitment)
  },
  frogSignerPubkeyAx: {
    type: "string",
    value:
      "6827523554590803092735941342538027861463307969735104848636744652918854385131",
  },
  frogSignerPubkeyAy: {
    type: "string",
    value:
      "19079678029343997910757768128548387074703138451525650455405633694648878915541",
  },
  // semaphoreIdentityTrapdoor: {
  //   type: "string",
  //   value:
  //     "19203180509052113016252601264864235852564023528134367070099013180198396222",
  // },
  // semaphoreIdentityNullifier: {
  //   type: "string",
  //   value:
  //     "46501085880889723880043204259130159126257178560019589221443961884550616786",
  // },
  watermark: { type: "string", value: "2718" },
  frogSignatureR8x: {
    type: "string",
    value:
      "19084778559285681898431269020586147882110166049035748906986371724723192016935",
  },
  frogSignatureR8y: {
    type: "string",
    value:
      "1523838105173306144821693157117855288580263724059184761875996521708759466326",
  },
  frogSignatureS: {
    type: "string",
    value:
      "2559171339443305966055733973400916029726138389097395261427367276578225928170",
  },
  externalNullifier: {
    type: "string",
    value:
      "10661416524110617647338817740993999665252234336167220367090184441007783393",
  },
  reservedField1: { type: "string", value: "0" },
  reservedField2: { type: "string", value: "0" },
  reservedField3: { type: "string", value: "0" },

  zupass_title: {
    type: "string",
    value: "test frog 3",
  },
  zupass_display: { type: "string", value: "collectable" },
  zupass_image_url: {
    type: "string",
    value:
      "https://upload.wikimedia.org/wikipedia/commons/e/eb/Drawing_for_beginners_%281920%29_%2814566679909%29.jpg",
  },
  zupass_description: {
    type: "string",
    value:
      "this is a test frog while we wait for the great frog(crypto) migration",
  },
};
