// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

import "./common/Singleton.sol";
import "./common/StorageAccessible.sol";
import "./common/NativeCurrencyPaymentFallback.sol";
import "./base/ModuleManager.sol";
import "./base/ProofManager.sol";
import "./handler/TokenCallbackHandler.sol";
import "./external/FusionContext.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/interfaces/IERC20Metadata.sol";
import "./common/NativeCurrencyPaymentFallback.sol";
import {Enum} from "./libraries/Enum.sol";
import {Transaction} from "./libraries/Transaction.sol";
import {Quote} from "./libraries/Quote.sol";

/**
 * @title Fusion - A User Friendly Smart Contract Wallet powered by ZK-SNARKs
 * @dev Most important concepts :
 *    - TxVerifier: Address of the Noir based ZK-SNARK verifier contract that will be used to verify proofs and execute transactions on the Fusion Wallet
 *    - TxHash: The hash used as a public inputs for the transaction verifier
 *    - nonce: The nonce of the Fusion Wallet
 * @author Anoy Roy Chowdhury - <anoy@valerium.id>
 */

contract Fusion is
    Singleton,
    StorageAccessible,
    ModuleManager,
    ProofManager,
    TokenCallbackHandler,
    NativeCurrencyPaymentFallback,
    FusionContext
{
    string public constant VERSION = "1.0.0";

    // The address of the Noir based ZK-SNARK verifier contract
    address public TxVerifier;

    // The hash used as a public inputs for verifiers
    bytes32 public TxHash;

    // The nonce of the Fusion Wallet
    uint256 private nonce;

    event SetupFusion(address txVerifier, bytes32 txHash);

    // This constructor ensures that this contract can only be used as a singleton for Proxy contracts
    constructor() {
        /**
         * By setting the TxHash to bytes32(uint256(1)), it is not possible to call setupFusion anymore,
         * This is an unusable Fusion Wallet, and it is only used to deploy the proxy contract
         */
        TxHash = bytes32(uint256(1));
    }

    /**
     * @notice Initializes the Fusion Wallet
     * @dev The function is called only once during deployment
     *      If the proxy was created without setting up, anyone can call setup and claim the proxy
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
    ) external {
        require(TxVerifier == address(0), "Fusion: already initialized");
        require(TxHash == bytes32(uint256(0)), "Fusion: already initialized");

        TxVerifier = _txVerifier;
        TxHash = _txHash;

        setupModules(to, data);

        emit SetupFusion(_txVerifier, _txHash);
    }

    /**
     * @notice Executes a transaction
     * @param _proof The zk-SNARK proof
     * @param txData call to perform
     */
    function executeTx(
        bytes calldata _proof,
        Transaction.TransactionData calldata txData
    ) public payable returns (bool success) {
        // Verifying the proof
        require(
            verify(
                _proof,
                Transaction.getTxHash(
                    txData,
                    _useNonce(),
                    getChainId(),
                    address(0),
                    0,
                    0,
                    0
                ),
                TxHash,
                TxVerifier
            ),
            "Fusion: invalid proof"
        );

        // Execute the call
        success = execute(
            txData.to,
            txData.value,
            txData.data,
            txData.operation,
            txData.gasLimit
        );
    }

    /**
     * @notice Executes a batch of transactions.
     * @dev This method will revert if any of the transactions fail.
     * @param _proof The zk-SNARK proof
     * @param transactions Array of Transaction objects.
     */
    function executeBatchTx(
        bytes calldata _proof,
        Transaction.TransactionData[] calldata transactions
    ) public payable {
        // Verifying the proof
        require(
            verify(
                _proof,
                Transaction.getTxBatchHash(
                    transactions,
                    _useNonce(),
                    getChainId(),
                    address(0),
                    0,
                    0,
                    0
                ),
                TxHash,
                TxVerifier
            ),
            "Fusion: invalid proof"
        );

        // Execute the batch call
        batchExecute(transactions);
    }

    /**
     * @notice Executes a transaction with a gas quote from a provider
     * @param _proof The zk-SNARK proof
     * @param txData call to perform
     * @param quote The gas quote
     */
    function executeTxWithProvider(
        bytes calldata _proof,
        Transaction.TransactionData calldata txData,
        Quote.GasQuote calldata quote
    ) public payable {
        // Verifying the proof
        require(
            verify(
                _proof,
                Transaction.getTxHash(
                    txData,
                    _useNonce(),
                    getChainId(),
                    quote.token,
                    quote.gasPrice,
                    quote.baseGas,
                    quote.deadline
                ),
                TxHash,
                TxVerifier
            ),
            "Fusion: invalid proof"
        );

        // Check if the balance is sufficient
        require(
            checkBalance(quote.token, quote.estimatedFees),
            "Fusion: insufficient balance"
        );

        // Check Deadline
        require(block.timestamp <= quote.deadline, "Fusion: deadline exceeded");

        uint256 startGas = gasleft();

        require(
            execute(
                txData.to,
                txData.value,
                txData.data,
                txData.operation,
                txData.gasLimit
            ),
            "Fusion: execution failed"
        );

        chargeFees(
            startGas,
            quote.gasPrice,
            quote.baseGas,
            quote.gasRecipient,
            quote.token
        );
    }

    /**
     * @notice Executes a batch of transactions with a gas quote from a provider
     * @param _proof The zk-SNARK proof
     * @param transactions Array of Transaction objects.
     * @param quote The gas quote
     */
    function executeBatchTxWithProvider(
        bytes calldata _proof,
        Transaction.TransactionData[] calldata transactions,
        Quote.GasQuote calldata quote
    ) public payable {
        // Verifying the proof
        require(
            verify(
                _proof,
                Transaction.getTxBatchHash(
                    transactions,
                    _useNonce(),
                    getChainId(),
                    quote.token,
                    quote.gasPrice,
                    quote.baseGas,
                    quote.deadline
                ),
                TxHash,
                TxVerifier
            ),
            "Fusion: invalid proof"
        );

        // Check if the balance is sufficient
        require(
            checkBalance(quote.token, quote.estimatedFees),
            "Fusion: insufficient balance"
        );

        // Check Deadline
        require(block.timestamp <= quote.deadline, "Fusion: deadline exceeded");

        uint256 startGas = gasleft();

        batchExecute(transactions);

        chargeFees(
            startGas,
            quote.gasPrice,
            quote.baseGas,
            quote.gasRecipient,
            quote.token
        );
    }

    /**
     * @notice Checks if the balance is sufficient
     * @param token The address of the token to be used for fees
     * @param estimatedFees The estimated fees for the transaction
     */
    function checkBalance(
        address token,
        uint256 estimatedFees
    ) internal view returns (bool) {
        if (token != address(0)) {
            uint8 decimals = IERC20Metadata(token).decimals();
            if (
                IERC20(token).balanceOf(address(this)) <
                estimatedFees / 10 ** (18 - decimals)
            ) {
                return false;
            }
        } else {
            if (address(this).balance < estimatedFees) {
                return false;
            }
        }

        return true;
    }

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
    ) public view returns (bytes4 magicValue) {
        if (verify(_signature, _hash, TxHash, TxVerifier)) {
            return 0x1626ba7e;
        } else {
            return 0xffffffff;
        }
    }

    /**
     * @notice Returns the nonce of the Fusion Wallet
     */
    function getNonce() public view returns (uint256) {
        return nonce;
    }

    /**
     * @notice Returns the nonce of the Fusion Wallet and increments it
     */
    function _useNonce() internal returns (uint256) {
        unchecked {
            return nonce++;
        }
    }

    /**
     * @notice Gets the chain ID of the current network
     */
    function getChainId() internal view returns (uint256 chainId) {
        assembly {
            chainId := chainid()
        }
    }
}
