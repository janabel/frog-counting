pragma circom 2.1.5;

// include "../node_modules/circomlib/circuits/comparators.circom";

// IVC formatted isZero circuit
// = circuit that checks whether or not the external_inputs are 0. 
    // if they are, then add 1 to the ivc_input = state. 
    // so state counts number of external inputs that are = 0.
    // ("counts" but not really - if external input invalid, then circuit just breaks) 
template IsZero() {
    signal input in;
    signal output out;

    signal inv;

    inv <-- in!=0 ? 1/in : 0;

    out <== -in*inv +1;
    in*out === 0;
}

template IsZeroIVC () {
    signal input ivc_input[1];
    signal input external_inputs[1];
    signal output ivc_output[1];

    component check_input = IsZero();
    external_inputs[0] ==> check_input.in;
    // check_input.out === 1;
    ivc_output[0] <== ivc_input[0] + check_input.out;
}

component main {public [ivc_input]} = IsZeroIVC();