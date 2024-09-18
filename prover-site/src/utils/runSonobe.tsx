import init, { frog_nova } from "../../sonobe-rust/pkg/sonobe_rust.js";

// async function loadWasm() {
//     await init();
//     greet("hi");
// }

async function readSerializedData(path: string) {
  const file_path = path;
  const response = await fetch(file_path);
  const bytes = await response.arrayBuffer();
  const res = new Uint8Array(bytes);
  // console.log("result from path " + path, res);
  return res;
}

export async function createProof(circuitInputs: object) {
  await init();

  try {
    console.log("running nova [js]");
    const r1cs_res = await readSerializedData("/frogIVC.r1cs");
    console.log("r1cs_res", r1cs_res);
    console.log("r1cs_res length:", r1cs_res.length);

    const wasm_res = await readSerializedData("/frogIVC.wasm");
    console.log("wasm_res", wasm_res);
    console.log("wasm_res length:", wasm_res.length);

    console.log("circuit inputs:", JSON.stringify(circuitInputs));

    const nova_pp_serialized_res = await readSerializedData(
      "/serialized_outputs/nova_pp_serialized.bin"
    );
    console.log("nova_pp_serialized_res", nova_pp_serialized_res);
    console.log("nova_pp_serialized_res length", nova_pp_serialized_res.length);

    const nova_vp_serialized_res = await readSerializedData(
      "/serialized_outputs/nova_vp_serialized.bin"
    );
    console.log("nova_vp_serialized_res", nova_vp_serialized_res);
    console.log("nova_vp_serialized_res length", nova_vp_serialized_res.length);

    const g16_pk_serialized_res = await readSerializedData(
      "/serialized_outputs/g16_pk_serialized.bin"
    );
    console.log("g16_pk_serialized_res", g16_pk_serialized_res);
    console.log("g16_pk_serialized_res length", g16_pk_serialized_res.length);

    const g16_vk_serialized_res = await readSerializedData(
      "/serialized_outputs/g16_vk_serialized.bin"
    );
    console.log("g16_vk_serialized_res", g16_vk_serialized_res);
    console.log("g16_vk_serialized_res length", g16_vk_serialized_res.length);

    // frog_nova(r1cs_bytes: Uint8Array,
    // wasm_bytes: Uint8Array,
    // frogs_js: any,
    // nova_pp_serialized: Uint8Array,
    // nova_vp_serialized: Uint8Array,
    // g16_vk_serialized: Uint8Array,
    // g16_pk_serialized: Uint8Array) {...}

    frog_nova(
      r1cs_res,
      wasm_res,
      JSON.stringify(circuitInputs),
      nova_pp_serialized_res,
      nova_vp_serialized_res,
      g16_vk_serialized_res,
      g16_pk_serialized_res
    );

    console.log("succesfully ran frog_nova WAHOOO???");
  } catch (e) {
    console.error("Error from Rust:", e);
  }
}
