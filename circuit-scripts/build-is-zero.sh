# rm previous files
rm -r ./circuits/isZeroIVC_js
rm circuits/isZeroIVC.r1cs
rm circuits/isZeroIVC.sym

cd circuits
npm install
cd ..

# circom ./circuit/keccak-chain.circom --r1cs --sym --wasm --prime bn128 --output ./circuit/
circom ./circuits/isZeroIVC.circom --r1cs --sym --wasm --prime bn128 --output ./circuits/
