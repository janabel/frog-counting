/**
 * Converts a binary string to a Uint8Array.
 * @param {string} binaryString - The binary string to convert.
 * @returns {Uint8Array} - The resulting Uint8Array.
 */
export function binaryStringToUint8Array(binaryString) {
  // Ensure the binary string's length is a multiple of 8 by padding with leading zeros
  const paddedBinaryString = binaryString.padStart(
    Math.ceil(binaryString.length / 8) * 8,
    "0"
  );

  // Create a Uint8Array with the correct size
  const byteArray = new Uint8Array(paddedBinaryString.length / 8);

  // Process the binary string in chunks of 8 bits
  for (let i = 0; i < paddedBinaryString.length; i += 8) {
    // Get the 8-bit chunk
    const byteString = paddedBinaryString.slice(i, i + 8);

    // Convert the 8-bit chunk into a byte (integer between 0 and 255)
    const byteValue = parseInt(byteString, 2);

    // Add the byte to the Uint8Array
    byteArray[i / 8] = byteValue;
  }

  return byteArray;
}

// // Example usage:
// const binaryString = "0001010110100011";
// const uint8Array = binaryStringToUint8Array(binaryString);
// console.log(uint8Array);
