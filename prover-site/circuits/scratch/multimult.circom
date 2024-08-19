pragma circom 2.1.6;

include "circomlib/poseidon.circom";
// include "https://github.com/0xPARC/circom-secp256k1/blob/master/circuits/bigint.circom";

template MultiMuliplication (N) {
    signal input a[N];
    signal input b[N];
    signal output c[N];
    
    for(var i=0; i<N; i++){
        c[i] <== a[i] * b[i];
    }
}

component main { public [ a ] } = MultiMuliplication(2);

/* INPUT = {
    "a": [5, 1],
    "b": [7, 2]
} */