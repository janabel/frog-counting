pragma circom 2.1.5;

// raw is zero circuit below, but not in format for sonobe. sonobe format requires ivc_inputs, outputs, etc.

template IsZero() {
    signal input in;
    signal output out;

    signal inv;
    inv <-- in!=0 ? 1/in : 0;
    
    out <== -in*inv + 1;
    in*out === 0;
    out === 1;
}

// for a input & output of 32 bytes:
component main = IsZero();
// only importing to use in isZeroIVC, commented out bc don't want to instantiate
