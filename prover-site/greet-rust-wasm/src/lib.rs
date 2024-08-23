mod keccak_chain;
mod utils;

use wasm_bindgen::prelude::*;
use keccak_chain::*;
use web_sys::console;
use console_error_panic_hook;

#[wasm_bindgen]
pub fn log_message(message: &str) {
    console::log_1(&message.into());
}

#[wasm_bindgen]
extern {
    pub fn alert(s: &str);
}

#[wasm_bindgen]
pub fn greet(name: &str) {
    alert(&format!("Hello, {}!", name));
    println!("hi");
}

#[wasm_bindgen]
pub fn add(x: i32, y: i32) -> i32 {
    x + y
}


#[wasm_bindgen]
pub fn run_sonobe(r1cs_bytes: Vec<u8>, wasm_bytes: Vec<u8>) {
    alert("running sonobe");
    let out = full_flow(r1cs_bytes, wasm_bytes);
    alert(&out);
}