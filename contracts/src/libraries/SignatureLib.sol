pragma solidity ^0.8.20;

// SPDX-License-Identifier: UNLICENSED

import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

/**
 * @title SignatureLib
 * @notice Library to wrap ECDSA recovery with potential extra checks
 */
library SignatureLib {
    /**
     * @notice Recovers the signer address from a message hash and signature
     * @param messageHash The hash of the message (already prefixed if required)
     * @param signature The signature bytes
     * @return signer The recovered address
     */
    function recoverSigner(bytes32 messageHash, bytes memory signature)
        internal
        pure
        returns (address signer)
    {
        // Using OpenZeppelin's ECDSA
        signer = ECDSA.recover(messageHash, signature);
    }
}