// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

import "../base/Verifier.sol";
import "../handler/ProofHandler.sol";

/**
 * @title ServerHandler - A generic base contract that allows callers to verify server proofs.
 * @author Anoy Roy Chowdhury - <anoy@valerium.id>
 * @notice Verifies server proofs using the provided verifier contract.
 */

abstract contract ServerHandler is ProofHandler, Verifier {
    // The address of the EOA that deployed the contract
    address private GenesisAddress;

    // The address of the server verifier
    address internal ServerVerifier;

    // The hash of the server
    bytes32 internal serverHash;

    // Initializing the Genesis Address
    constructor() {
        GenesisAddress = msg.sender;
    }

    // Modifier to check if the caller is the genesis address
    modifier onlyGenesis() {
        require(
            msg.sender == GenesisAddress,
            "Only genesis can call this function"
        );
        _;
    }

    /**
     * @notice Transfers the genesis address to a new address
     * @param _newGenesis The new genesis address
     */
    function transferGenesis(address _newGenesis) external onlyGenesis {
        GenesisAddress = _newGenesis;
    }

    /**
     * @notice Sets up the server verifier and server hash
     * @param _serverVerifier Address of the server verifier
     * @param _serverHash Hash of the server
     */
    function setupServer(
        address _serverVerifier,
        bytes32 _serverHash
    ) external onlyGenesis {
        ServerVerifier = _serverVerifier;
        serverHash = _serverHash;
    }

    /**
     * @notice Verifies the server proof
     * @param _proof The proof to be verified
     * @param _serverHash The hash of the server
     * @param _verifier The address of the verifier
     * @param _domain The domain of the request
     * @param _addr The signing address
     */
    function verify(
        bytes calldata _proof,
        bytes32 _serverHash,
        address _verifier,
        bytes4 _domain,
        address _addr
    ) internal returns (bool) {
        bytes32[] memory publicInputs;

        require(isProofDuplicate(_proof) == false, "Proof already exists");

        // Add the proof to prevent reuse
        addProof(_proof);

        // Use scope here to limit variable lifetime and prevent `stack too deep` errors
        {
            publicInputs = new bytes32[](4);
            publicInputs[0] = _serverHash;
            publicInputs[1] = bytes32(uint256(uint32(_domain)));
            publicInputs[2] = bytes32(getChainId());
            publicInputs[3] = bytes32(uint256(uint160(_addr)));
        }

        return verifyProof(_proof, publicInputs, _verifier);
    }

    /**
     * @notice Returns the chain id
     */
    function getChainId() public view returns (uint256) {
        uint256 id;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            id := chainid()
        }
        return id;
    }
}
