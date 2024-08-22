function parseProofString(proofString: string) {
  // Regular expressions to extract values
  const aRegex = /a:\s*\(([^,]+),\s*([^)]+)\)/;
  const bRegex =
    /b:\s*\(\s*QuadExtField\(([^)]+?)\s*\+\s*([^)]+?)\s*\*\s*u\),\s*QuadExtField\(([^)]+?)\s*\+\s*([^)]+?)\s*\*\s*u\)\s*\)/;
  const cRegex = /c:\s*\(([^,]+),\s*([^)]+)\)/;

  // Extract values from the string
  const aMatch = proofString.match(aRegex);
  const bMatch = proofString.match(bRegex);
  const cMatch = proofString.match(cRegex);

  if (!aMatch || !bMatch || !cMatch) {
    throw new Error("Proof string does not match expected format");
  }

  const a = [aMatch[1].trim(), aMatch[2].trim(), "1"];
  const b = [
    [bMatch[1].trim(), bMatch[2].trim()],
    [bMatch[3].trim(), bMatch[4].trim()],
  ];
  const c = [cMatch[1].trim(), cMatch[2].trim(), "1"];

  // Build and return JSON object
  return {
    pi_a: a.map((val) => val.replace(/^\+/, "").trim()), // Clean up any leading '+' signs
    pi_b: [
      b[0].map((val) => val.replace(/ \* u$/, "").trim()), // Remove trailing ' * u'
      b[1].map((val) => val.replace(/ \* u$/, "").trim()), // Remove trailing ' * u'
      ["1", "0"],
    ],
    pi_c: c.map((val) => val.replace(/^\+/, "").trim()), // Clean up any leading '+' signs
    protocol: "groth16",
    curve: "bn128",
  };
}

// Example usage
const proofString = `Proof { 
      a: (3014672007231952391718194484713940165323843493919769924675295759031534057661, 1431881007400488584887541955420295053753746547895554599160748570916066494245), 
      b: (
          QuadExtField(7031116753136549222691111864981749471340253800786031612244432026293988324235 + 6890030197945800172327994784987226772680771446510382683210373212317751529286 * u), 
          QuadExtField(7272227115798645518899117913851783866248080487933536099367483403537635406002 + 18889049319206267999353646216605115062535660937494365669609808538167288957140 * u)
      ), 
      c: (3699130915744032802513208502799702273129025893129769520535102284339283316711, 14128477270156505747225883138438139466689588722536207087731363570351596017473) 
  }`;

const proofJson = parseProofString(proofString);
console.log(JSON.stringify(proofJson, null, 2));
