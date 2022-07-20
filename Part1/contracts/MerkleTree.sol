//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import { PoseidonT3 } from "./Poseidon.sol"; //an existing library to perform Poseidon hash on solidity
import "./verifier.sol"; //inherits with the MerkleTreeInclusionProof verifier contract

contract MerkleTree is Verifier {
    uint256[] public hashes; // the Merkle tree in flattened array form
    uint256 public index = 0; // the current index of the first unfilled leaf
    uint256 public root; // the current Merkle root

    constructor() {
        for ( uint i = 0; i < 2**4 - 1; i++ ) {
            hashes.push(0);
        }

        root = 0;
    }

    function insertLeaf(uint256 hashedLeaf) public returns (uint256) {
        require(index < 8);
        
        hashes[index] = hashedLeaf;
        uint leaves = 8;

        for ( uint i = index; i < 14; i = leaves + i / 2 ) {
            uint[2] memory pair;
            if ( i % 2 == 0 ) {
                pair[0] = hashes[i];
                pair[1] = hashes[i+1];
            } else {
                pair[0] = hashes[i-1];
                pair[1] = hashes[i];
            }
            
            uint hash = PoseidonT3.poseidon(pair);
            uint parentI = leaves + i/2;
            hashes[parentI] = hash;
        }

        root = hashes[leaves * 2 - 2];
        index++;
        return root;
    }

    function verify(
            uint[2] memory a,
            uint[2][2] memory b,
            uint[2] memory c,
            uint[1] memory input
        ) public view returns (bool) {
            return input[0] == root && verifyProof(a, b, c, input);
    }
}
