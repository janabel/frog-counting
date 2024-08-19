# FROG-counting

Application allowing you to generate proofs about having n frogs using folding schemes and the Sonobe library

## Development

Start by running:
`npm init -y`
`npm install`

To initialize a Vite bundler for opening the webpage on a local host, run the following command:
`npm create vite@latest ./`

Then install Solidity via the following command:
`brew install solidity`
OR
`npm install -g solc`

Check that you have installed properly by running:
`solc --version`
which should print a solc version. Otherwise you may need to configure your path manually.

## Building circuits

To run circuit build scripts, cd into the circuit-scripts directory. Put all circuits in the circuits directory.
`sh circuit-scripts/build-is-zero.sh`

## TODOS:

- [x] basic website with circom circuit prove/verify
- [x] frog circuit working with manual inputs
- [x] frog circuit working in browser with frog copy paste
- [x] get original circom_full_flow in sonobe working
- [x] substitute with an isZero circuit
- [x] substitute with the frog circuit
- [x] write javascript script for converting normal frog json into split frog json (following script.js logic)
- [ ] break frogVerify up, get proof and display from rust code for user to copy paste into verifier function
- [ ] run entire frogVerify rust code in browser (compile to wasm, fetch inputs)
