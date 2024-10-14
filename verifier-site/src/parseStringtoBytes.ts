export function stringToByteArray(stringArray: string) {
  const numArray = JSON.parse(stringArray);
  const uint8Array = new Uint8Array(numArray);
  return uint8Array;
}

//test
const binaryString = "[0, 25, 236, 178]";
const byteArray = stringToByteArray(binaryString);
console.log(byteArray);
console.log(typeof byteArray);
