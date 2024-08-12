# rm previous files
rm -r ./circuits/isZero_js
rm circuits/isZero.r1cs
rm circuits/isZero.sym

cd circuits
npm install
cd ..

# circom ./circuit/keccak-chain.circom --r1cs --sym --wasm --prime bn128 --output ./circuit/
circom ./circuits/isZeroIVC.circom --r1cs --sym --wasm --prime bn128 --output ./circuits/
