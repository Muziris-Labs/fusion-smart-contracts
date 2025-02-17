// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

import {Enum} from "../libraries/Enum.sol";
import {Transaction} from "../libraries/Transaction.sol";
import {Quote} from "../libraries/Quote.sol";

/**
 * @title IFusion - Fusion Wallet Interface
 * @author Anoy Roy Chowdhury - <anoyroyc3545@gmail.com>
 */

interface IFusion {
    event SetupFusion(address txVerifier, bytes32 txHash);

    /**
     * @notice Initializes the Fusion Wallet
     * @param _txVerifier The address of the Noir based ZK-SNARK verifier contract
     * @param _txHash The hash used as a public inputs for verifiers
     * @param to The destination address of the call to execute
     * @param data The data of the call to
     */
    function setupFusion(
        address _txVerifier,
        bytes32 _txHash,
        address to,
        bytes calldata data
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
     * @notice Executes a batch of transactions
     * @param _proof The zk-SNARK proof
     * @param transactions Array of Transaction objects
     */
    function executeBatchTx(
        bytes calldata _proof,
        Transaction.TransactionData[] calldata transactions
    ) external payable;

    /**
     * @notice Executes a transaction with a trusted forwarder
     * @param _proof The zk-SNARK proof
     * @param txData call to perform
     * @param quote The gas quote
     */
    function executeTxWithProvider(
        bytes calldata _proof,
        Transaction.TransactionData calldata txData,
        Quote.GasQuote calldata quote
    ) external payable;

    /**
     * @notice Executes a batch of transactions with a trusted forwarder
     * @param _proof The zk-SNARK proof
     * @param transactions Array of Transaction objects
     * @param quote The gas quote
     */
    function executeBatchTxWithProvider(
        bytes calldata _proof,
        Transaction.TransactionData[] calldata transactions,
        Quote.GasQuote calldata quote
    ) external payable;

    /**
     * @notice Verifies if the proof is valid or not
     * @param _hash the message which is used to verify zero-knowledge proof
     * @param _signature Noir based zero-knowledge proof
     * @return magicValue The magic value indicating if the signature is valid
     */
    function isValidSignature(
        bytes32 _hash,
        bytes calldata _signature
    ) external view returns (bytes4 magicValue);

    /**
     * @notice Returns the nonce of the Fusion Wallet
     * @return The current nonce value
     */
    function getNonce() external view returns (uint256);

    /**
     * @notice Returns the version of the contract
     * @return The version string
     */
    function VERSION() external view returns (string memory);

    /**
     * @notice Returns the address of the transaction verifier
     * @return The address of the verifier contract
     */
    function TxVerifier() external view returns (address);

    /**
     * @notice Returns the transaction hash used as public input
     * @return The transaction hash
     */
    function TxHash() external view returns (bytes32);
}
