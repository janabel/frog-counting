#!/bin/bash

# rm previous files
rm -r ./keccak-circuit/keccak-chain_js
rm keccak-circuit/keccak-chain.r1cs
rm keccak-circuit/keccak-chain.sym

cd keccak-circuit
npm install
cd ..

circom ./keccak-circuit/keccak-chain.circom --r1cs --sym --wasm --prime bn128 --output ./keccak-circuit/