// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

import "../libraries/Enum.sol";
import "../libraries/Transaction.sol";

/**
 * @title IFusion - Interface for Fusion Master Contract
 * @author Anoy Roy Chowdhury - <anoy@valerium.id>
 * @notice This Interface is used to interact with Fusion Master Contract
 */

interface IFusion {
    // Returns the version of the Fusion Master Contract
    function VERSION() external view returns (string memory);

    // Returns the domain of the Fusion Master Contract
    function DOMAIN() external view returns (bytes32);

    // Returns the address of the TxVerifier contract
    function TxVerifier() external view returns (address);

    // Returns the address of the Forwarder contract
    function TxHash() external view returns (bytes32);

    // Returns the address of the GasTank contract
    function GasTank() external view returns (address);

    /**
     * @notice Initializes the Fusion Wallet
     * @dev The function is called only once during deployment
     *      If the proxy was created without setting up, anyone can call setup and claim the proxy
     * @param _domain  The domain of the Fusion Wallet
     * @param _txVerifier The address of the Noir based ZK-SNARK verifier contract
     * @param _forwarder The address of the trusted forwarder
     * @param _gasTank The address of the gas tank contract or EOA
     * @param _txHash The hash used as a public inputs for verifiers
     */
    function setupFusion(
        bytes32 _domain,
        address _txVerifier,
        address _forwarder,
        address _gasTank,
        bytes32 _txHash
    ) external;

    /**
     * @notice Executes a transaction
     * @param _proof The zk-SNARK proof
     * @param txData call to perform
     */
    function executeTx(
        bytes calldata _proof,
        Transaction.TransactionData calldata txData
    ) external payable returns (bool success);

    /**
     * @notice Executes a batch of transactions.
     * @dev This method will revert if any of the transactions fail.
     * @param _proof The zk-SNARK proof
     * @param transactions Array of Transaction objects.
     */
    function executeBatchTx(
        bytes calldata _proof,
        Transaction.TransactionData[] calldata transactions
    ) external payable;

    /**
     * @notice Executes a transaction with a trusted forwarder
     * @dev The function is called by the trusted forwarder
     *      The function will revert if the proof is invalid or the execution fails
     * @param _proof The zk-SNARK proof
     * @param txData call to perform
     * @param token The address of the token to be used for fees
     * @param gasPrice The gas price for the transaction
     * @param baseGas The base gas for the transaction
     * @param estimatedFees The estimated fees for the transaction
     */
    function executeTxWithForwarder(
        bytes calldata _proof,
        Transaction.TransactionData calldata txData,
        address from,
        address token,
        uint256 gasPrice,
        uint256 baseGas,
        uint256 estimatedFees
    ) external payable;

    /**
     * @notice Executes a batch of transactions with a trusted forwarder
     * @dev The function is called by the trusted forwarder
     *      The function will revert if the proof is invalid or any of the execution fails
     * @param _proof The zk-SNARK proof
     * @param transactions Array of Transaction objects.
     * @param token The address of the token to be used for fees
     * @param gasPrice The gas price for the transaction
     * @param baseGas The base gas for the transaction
     * @param estimatedFees The estimated fees for the transaction
     */
    function executeBatchTxWithForwarder(
        bytes calldata _proof,
        Transaction.TransactionData[] calldata transactions,
        address from,
        address token,
        uint256 gasPrice,
        uint256 baseGas,
        uint256 estimatedFees
    ) external payable;

    /**
     * @notice Verifies if the proof is valid or not
     * @dev The parameters are named to maintain the same implementation as EIP-1271
     *      Should return whether the proof provided is valid for the provided data
     * @param _hash the message which is used to verify zero-knowledge proof
     * @param _signature Noir based zero-knowledge proof
     */
    function isValidSignature(
        bytes32 _hash,
        bytes calldata _signature
    ) external view returns (bytes4 magicValue);

    /**
     * @notice Returns the nonce of the Fusion Wallet
     */
    function getNonce() external view returns (uint256);
}
