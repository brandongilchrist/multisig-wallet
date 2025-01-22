pragma solidity ^0.8.20;

// SPDX-License-Identifier: UNLICENSED

import {SignatureLib} from "../libraries/SignatureLib.sol";

/**
 * @title MultisigWallet
 * @notice Core storage and initialization for a k-of-n multisig.
 *         Transaction execution and signer update logic will be added in subsequent issues.
 */
contract MultisigWallet {
    // =================================================
    //                         ERRORS
    // =================================================
    error InvalidThreshold(uint256 threshold);
    error DuplicateSigner(address signer);
    error ZeroAddress();
    error NotImplemented();

    // =================================================
    //                         EVENTS
    // =================================================
    event SignerAdded(address indexed signer);
    event SignerRemoved(address indexed signer);
    event ThresholdUpdated(uint256 newThreshold);

    // =================================================
    //                       STORAGE
    // =================================================
    uint256 private _threshold;
    uint256 private _nonce;
    mapping(address => bool) private _isSigner;

    /**
     * @notice Deploy the MultisigWallet with an initial set of signers and threshold.
     * @param initialSigners The array of addresses to set as signers
     * @param initialThreshold The number of signatures required (k)
     */
    constructor(address[] memory initialSigners, uint256 initialThreshold) {
        // Ensure threshold is valid
        if (initialThreshold == 0 || initialThreshold > initialSigners.length) {
            revert InvalidThreshold(initialThreshold);
        }

        // Add each signer
        for (uint256 i = 0; i < initialSigners.length; ) {
            address signer = initialSigners[i];
            if (signer == address(0)) revert ZeroAddress();
            if (_isSigner[signer]) revert DuplicateSigner(signer);

            _isSigner[signer] = true;
            emit SignerAdded(signer);

            unchecked {
                ++i;
            }
        }

        _threshold = initialThreshold;
        _nonce = 0;

        emit ThresholdUpdated(initialThreshold);
    }

    /**
     * @notice Returns the current threshold (k-of-n)
     */
    function getThreshold() external view returns (uint256) {
        return _threshold;
    }

    /**
     * @notice Returns the current nonce
     */
    function getNonce() external view returns (uint256) {
        return _nonce;
    }

    /**
     * @notice Check if an address is currently recognized as a signer
     * @param account The address to check
     * @return bool True if the address is a signer
     */
    function isSigner(address account) external view returns (bool) {
        return _isSigner[account];
    }

    /**
     * @notice Placeholder for transaction execution. Will be implemented in Issue #3.
     */
    function executeTransaction() external pure {
        revert NotImplemented();
    }

    /**
     * @notice Placeholder for signer management. Will be implemented in Issue #4.
     */
    function updateSigners() external pure {
        revert NotImplemented();
    }
}