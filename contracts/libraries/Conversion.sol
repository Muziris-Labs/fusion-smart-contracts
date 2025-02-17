// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Conversion - A contract that can convert to publicInputs compatible with UltraVerifier
 * @notice This contract is a library that provides functions to convert between different types
 * @author Anoy Roy Chowdhury - <anoy@valerium.id>
 */

library Conversion {
    /**
     * @notice Convert a bytes32 value to a padded bytes32 value
     * @param value The value to be converted to bytes32
     */
    function convertToPaddedByte32(
        bytes32 value
    ) internal pure returns (bytes32) {
        bytes32 paddedValue;
        paddedValue = bytes32(uint256(value) >> (31 * 8));
        return paddedValue;
    }

    /**
     * @notice Convert the message hash to public inputs
     * @param _message  The message hash
     * @param _hash  The hash of the user that verifies the proof
     */
    function convertToInputs(
        bytes32 _message,
        bytes32 _hash
    ) internal pure returns (bytes32[] memory) {
        bytes32[] memory byte32Inputs = new bytes32[](33);
        bytes32 messageHash = getEthSignedMessageHash(_message);
        for (uint256 i = 0; i < 32; i++) {
            byte32Inputs[i] = convertToPaddedByte32(messageHash[i]);
        }
        byte32Inputs[32] = _hash;

        return byte32Inputs;
    }

    /**
     * @notice Get the hash of a message that was signed
     * @param _messageHash The hash of the message that was signed
     */
    function getEthSignedMessageHash(
        bytes32 _messageHash
    ) public pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n32",
                    _messageHash
                )
            );
    }
}
