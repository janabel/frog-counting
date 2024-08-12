# rm previous files
rm -r ./circuit/isZero_js
rm circuit/isZero.r1cs
rm circuit/isZero.sym

cd circuit
npm install
cd ..

# circom ./circuit/keccak-chain.circom --r1cs --sym --wasm --prime bn128 --output ./circuit/
circom ./circuit/isZeroIVC.circom --r1cs --sym --wasm --prime bn128 --output ./circuit/
