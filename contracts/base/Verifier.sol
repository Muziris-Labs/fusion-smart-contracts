// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

/**
 * @title UltraVerifierInterface - Interface for verification of proofs
 * @author Anoy Roy Chowdhury - <anoy@valerium.id>
 * @notice This Interface is used to verify proofs using UltraVerifier
 */
interface UltraVerifierInterface {
    function verify(
        bytes calldata _proof,
        bytes32[] calldata _publicInputs
    ) external view returns (bool);
}

/**
 * @title Verifier - Base contract for verification of proofs
 * @dev This contract is used to verify proofs using UltraVerifier
 */
abstract contract Verifier {
    /**
     * @notice Verifies the proof and returns the result of verification.
     * @param _proof The proof inputs
     * @param _publicInputs The public inputs
     * @param _verifier The address of the verifier contract
     */
    function verifyProof(
        bytes calldata _proof,
        bytes32[] memory _publicInputs,
        address _verifier
    ) internal view returns (bool) {
        return UltraVerifierInterface(_verifier).verify(_proof, _publicInputs);
    }
}
