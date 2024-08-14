# rm previous files
rm -r ./circuits/with_external_inputs_js
rm circuits/with_external_inputs.r1cs
rm circuits/with_external_inputs.sym

cd circuits
npm install
cd ..

circom ./circuits/with_external_inputs.circom --r1cs --sym --wasm --prime bn128 --output ./circuits/