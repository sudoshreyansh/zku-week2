pragma circom 2.0.0;

include "../node_modules/circomlib/circuits/poseidon.circom";

template CheckRoot(n) { // compute the root of a MerkleTree of n Levels 
    signal input leaves[2**n];
    signal output root;

    var noNodes = 2**n;
    component hash[noNodes - 1];

    for ( var i = 0; i < noNodes - 1; i++ ) {
        hash[i] = Poseidon(2);
    }
    
    var hashIndex = 0;
    for ( var i = 0; i < noNodes; i+=2 ) {
        hash[hashIndex].inputs[0] <== leaves[i];
        hash[hashIndex].inputs[1] <== leaves[i+1];
        hashIndex++;
    }

    var outIndex = 0;
    noNodes /= 2;

    while ( noNodes > 1 ) {
        var startHashIndex = hashIndex; 
        for ( var i = outIndex; i < outIndex + noNodes; i+=2 ) {
            hash[hashIndex].inputs[0] <== hashIndex[i].out;
            hash[hashIndex].inputs[1] <== hashIndex[i+1].out;

            hashIndex++;
        }

        noNodes /= 2;
        outIndex = startHashIndex;
    }

    root <== hash[2**n - 2].out;
}

template Mux() {
    signal input in[2];
    signal input s;
    signal output out[2];

    s * (1 - s) === 0;
    out[0] <== (in[1] - in[0]) * s + in[0];
    out[1] <== (in[0] - in[1]) * s + in[1];
}

template MerkleTreeInclusionProof(n) {
    signal input leaf;
    signal input path_elements[n];
    signal input path_index[n]; // path index are 0's and 1's indicating whether the current element is on the left or right
    signal output root; // note that this is an OUTPUT signal

    component hash[n];
    component mux[n];
    for ( var i = 0; i < n; i++ ) {
        hash[i] = Poseidon(2);
        mux[i] = Mux();
    }

    for ( var i = 0; i < n; i++ ) {
        if ( i == 0 ) {
            mux[i].in[0] <== leaf; 
        } else {
            mux[i].in[0] <== hash[i-1].out;
        }

        mux[i].in[1] <== path_elements[i];
        mux[i].s <== path_index[i];

        hash[i].inputs[0] <== mux[i].out[0];
        hash[i].inputs[1] <== mux[i].out[1];
    }

    root <== hash[n-1].out;
}