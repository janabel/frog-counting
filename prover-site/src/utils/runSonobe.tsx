import init, { frog_nova } from '../../sonobe-rust/pkg/sonobe_rust.js';

// async function loadWasm() {
//     await init();
//     greet("hi");
// }

  
export async function createProof(circuitInputs: Object){
    await init();

    try {
        console.log("running nova [js]");
        const r1cs_path = "../../../circuits/build/frogIVC.r1cs";
        const r1cs_response = await fetch(r1cs_path);
        const r1cs_bytes = await r1cs_response.arrayBuffer();
        const r1cs_res = new Uint8Array(r1cs_bytes);
        console.log("r1cs_res", r1cs_res);

        const wasm_path = "../../../circuits/build/frogIVC_js/frogIVC.wasm";
        const wasm_response = await fetch(wasm_path);
        const wasm_bytes = await wasm_response.arrayBuffer();
        const wasm_res = new Uint8Array(wasm_bytes);
        console.log("wasm_res", wasm_res);

        console.log(JSON.stringify(circuitInputs));

        frog_nova(r1cs_res, wasm_res, JSON.stringify(circuitInputs));
    } catch (e) {
        console.error('Error from Rust:', e);
    }
    
}