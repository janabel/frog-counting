function binaryStringToByteArray(binaryString) {
  // Ensure the binary string's length is a multiple of 8 by padding with leading zeros
  const paddedBinaryString = binaryString.padStart(
    Math.ceil(binaryString.length / 8) * 8,
    "0"
  );

  const byteArray = [];

  // Process the binary string in chunks of 8 bits
  for (let i = 0; i < paddedBinaryString.length; i += 8) {
    // Get the 8-bit chunk
    const byteString = paddedBinaryString.slice(i, i + 8);

    // Convert the 8-bit chunk into a byte (integer between 0 and 255)
    const byteValue = parseInt(byteString, 2);

    // Add the byte to the array
    byteArray.push(byteValue);
  }

  return byteArray;
}

// Example usage:
const binaryString = "0001010110100011";
const byteArray = binaryStringToByteArray(binaryString);
