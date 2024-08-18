use std::fs;
use std::io::Result;
use serde::Deserialize;
use serde_json::Value;

#[derive(Debug, Deserialize)]
struct Frog {
    frogId: u32,
    biome: u32,
    rarity: u32,
    temperament: u32,
    jump: u32,
    speed: u32,
    intelligence: u32,
    beauty: u32,
    timestampSigned: u64,
    ownerSemaphoreId: String,
    frogSignerPubkeyAx: String,
    frogSignerPubkeyAy: String,
    watermark: String,
    frogSignatureR8x: String,
    frogSignatureR8y: String,
    frogSignatureS: String,
    externalNullifier: String,
    reservedField1: String,
    reservedField2: String,
    reservedField3: String,
}

#[derive(Debug, Deserialize)]
struct FrogsJson {
    #[serde(flatten)]
    frogs: std::collections::HashMap<String, Frog>,
}

fn main() -> Result<()> {
    // Path to the JSON file
    let file_path = "./frogCircuitInputs.json";

    // Read the file contents into a string
    let contents = fs::read_to_string(file_path)?;

    // Parse the JSON string into a HashMap
    let parsed_json: FrogsJson = serde_json::from_str(&contents)?;

    // Print the parsed data
    println!("{:?}", parsed_json);

    Ok(())
}
