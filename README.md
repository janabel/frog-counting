# POD-counting

Application allowing you to generate proofs about having n PODS using folding schemes and the Sonobe library

## Development

Using a Vite bundler. To start, run the following commands:

`npm install`
`npm create vite@latest ./`

## Building circuits

To run circuit build scripts, cd into the circuit-scripts directory. Put all circuits in the circuits directory.

## TODOS:

- figure out why parcel isn't serving static files in public...
- hmmmm

Assuming rust and circom have been installed:

- `sh circuit-scripts/build-is-zero.sh`
- `cargo test --release is_zero -- --nocapture`
