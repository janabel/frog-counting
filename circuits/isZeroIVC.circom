pragma circom 2.0.0;

include "./isZero.circom";

// IVC formatted isZero circuit
template IsZeroIVC () {

    // have a circuit that checks whether or not the external_inputs are 0. 
    // if they are, then add 1 to the ivc_input = state. 
    // so state counts number of external inputs that are = 0. ("counts" but not really - if external input invalid, then circuit just breaks) 

    signal input ivc_input[1];
    signal input external_inputs[1];
    signal output ivc_output[1];

    component check_input = IsZero();
    check_input.in <== external_inputs[0];
    check_input.out === 0;

    ivc_output[0] <== ivc_input[0] + 1;
}

component main {public [ivc_input]} = IsZeroIVC();