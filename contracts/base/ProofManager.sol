// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;
import "./Verifier.sol";
import "../libraries/Conversion.sol";

/**
 * @title Proof Manager - Converts given hash to public inputs and verifies the proof
 * @notice This contract is a base contract for coverting given hash to public inputs and verifying the proof
 * @author Anoy Roy Chowdhury - <anoy@valerium.id>
 */
abstract contract ProofManager is Verifier {
    /**
     * @notice Verifies the proof and returns the result of verification.
     * @param _proof The proof inputs
     * @param _message The message hash
     * @param _hash The hash of the user that verifies the proof
     * @param _verifier The address of the verifier contract
     * @param _verifyingAddress The address of the EOA that signed the message through trusted forwarder
     * @param _signingAddress The address of the EOA that executed the transaction
     * @dev _verifyingAddress should be address(0) if the message was signed directly by the EOA
     */
    function verify(
        bytes calldata _proof,
        bytes32 _message,
        bytes32 _hash,
        address _verifier,
        address _verifyingAddress,
        address _signingAddress
    ) internal view returns (bool) {
        bytes32[] memory publicInputs = Conversion.convertToInputs(
            _message,
            _hash,
            _verifyingAddress,
            _signingAddress
        );
        return verifyProof(_proof, publicInputs, _verifier);
    }
}
