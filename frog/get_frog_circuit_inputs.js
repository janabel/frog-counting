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
