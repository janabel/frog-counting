#!/bin/bash
 
CIRCUITS_DIR=../circuits
PHASE1=../circuits/ptau/powersOfTau28_hez_final_20.ptau
BUILD_DIR=../circuits/build
CIRCUIT_NAME=isZeroIVC
PUBLIC_DIR=../public
SRC_DIR=../src
 
if [ -f "$PHASE1" ]; then
    echo "Found Phase 1 ptau file"
else
    echo "No Phase 1 ptau file found. Exiting..."
    exit 1
fi
 
if [ ! -d "$BUILD_DIR" ]; then
    echo "No build directory found. Creating build directory..."
    mkdir -p "$BUILD_DIR"
fi


# Compile circuit and generate zkey/vkey

# echo "****COMPILING CIRCUIT****"
# start=`date +%s`
# circom "$CIRCUITS_DIR"/"$CIRCUIT_NAME".circom --r1cs --wasm --sym --c --wat --output "$BUILD_DIR"
# end=`date +%s`
# echo "DONE ($((end-start))s)"
 
# echo "****GENERATING ZKEY 0****"
# start=`date +%s`
# npx snarkjs groth16 setup "$BUILD_DIR"/"$CIRCUIT_NAME".r1cs "$PHASE1" "$BUILD_DIR"/"$CIRCUIT_NAME"_0.zkey
# end=`date +%s`
# echo "DONE ($((end-start))s)"
 
# echo "****CONTRIBUTE TO PHASE 2 CEREMONY****"
# start=`date +%s`
# npx snarkjs zkey contribute "$BUILD_DIR"/"$CIRCUIT_NAME"_0.zkey "$BUILD_DIR"/"$CIRCUIT_NAME"_1.zkey --name="First contributor" -e="random text for entropy"
# end=`date +%s`
# echo "DONE ($((end-start))s)"
 
# echo "****GENERATING FINAL ZKEY****"
# start=`date +%s`
# NODE_OPTIONS="--max-old-space-size=56000" npx snarkjs zkey beacon "$BUILD_DIR"/"$CIRCUIT_NAME"_1.zkey "$BUILD_DIR"/"$CIRCUIT_NAME"_final.zkey 12FE2EC467BD428DD0E966A6287DE2AF8DE09C2C5C0AD902B2C666B0895ABB75 10 -n="Final Beacon phase2"
# end=`date +%s`
# echo "DONE ($((end-start))s)"
 
# echo "****EXPORTING VKEY****"
# start=`date +%s`
# npx snarkjs zkey export verificationkey "$BUILD_DIR"/"$CIRCUIT_NAME"_final.zkey "$BUILD_DIR"/"$CIRCUIT_NAME"_vkey.json -v
# end=`date +%s`
# echo "DONE ($((end-start))s)"


# Generate and verify proof

echo "****GENERATING WITNESS FOR SAMPLE INPUT****"
start=`date +%s`
node "$BUILD_DIR"/"$CIRCUIT_NAME"_js/generate_witness.cjs "$BUILD_DIR"/"$CIRCUIT_NAME"_js/"$CIRCUIT_NAME".wasm "$CIRCUITS_DIR"/"input_isZeroIVC.json" "$BUILD_DIR"/witness.wtns
end=`date +%s`
echo "DONE ($((end-start))s)"

echo "****GENERATING PROOF FOR SAMPLE INPUT****"
start=`date +%s`
npx snarkjs groth16 prove "$BUILD_DIR"/"$CIRCUIT_NAME"_final.zkey "$BUILD_DIR"/witness.wtns "$BUILD_DIR"/proof.json "$BUILD_DIR"/public.json
end=`date +%s`
echo "DONE ($((end-start))s)"

echo "****VERIFYING PROOF FOR SAMPLE INPUT****"
start=`date +%s`
npx snarkjs groth16 verify "$BUILD_DIR"/"$CIRCUIT_NAME"_vkey.json "$BUILD_DIR"/public.json "$BUILD_DIR"/proof.json
end=`date +%s`
echo "DONE ($((end-start))s)"