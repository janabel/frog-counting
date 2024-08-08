const fs = require('fs');
const path = "circuits/build/multiplier_js/multiplier.wasm";
console.log(process.cwd())

// Check if the directory exists
if (fs.existsSync(path)) {
  console.log('Directory exists.');
} else {
  console.log('Directory does not exist.');
}
