// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

import "./common/Singleton.sol";
import "./common/StorageAccessible.sol";
import "./base/ModuleManager.sol";
import "./base/ProofManager.sol";
import "./handler/TokenCallbackHandler.sol";
import "./external/Fusion2771Context.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/interfaces/IERC20Metadata.sol";
import {Enum} from "./libraries/Enum.sol";
import {Transaction} from "./libraries/Transaction.sol";

/**
 * @title Fusion - A Smart Contract Wallet powered by ZK-SNARKs with support for Cross-Chain Transactions
 * @dev Most important concepts :
 *    - TxVerifier: Address of the Noir based ZK-SNARK verifier contract that will be used to verify proofs and execute transactions on the Fusion Wallet
 *    - Gas Tank: The gas tank is an EOA or a smart contract where the fees will be transferred
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
    Fusion2771Context
{
    string public constant VERSION = "1.0.0";

    // The address of the Noir based ZK-SNARK verifier contract
    address public TxVerifier;

    // The hash used as a public inputs for verifiers
    bytes32 public TxHash;

    // The address of the gas tank contract or EOA
    address public GasTank;

    // The nonce of the Fusion Wallet
    uint256 private nonce;

    event SetupFusion(
        address txVerifier,
        address forwarder,
        address gasTank,
        bytes32 txHash
    );

    /**
     * @notice Initializes the Fusion Wallet
     * @dev The function is called only once during deployment
     *      If the proxy was created without setting up, anyone can call setup and claim the proxy
     * @param _txVerifier The address of the Noir based ZK-SNARK verifier contract
     * @param _forwarder The address of the trusted forwarder
     * @param _gasTank The address of the gas tank contract or EOA
     * @param _txHash The hash used as a public inputs for verifiers
     */
    function setupFusion(
        address _txVerifier,
        address _forwarder,
        address _gasTank,
        bytes32 _txHash
    ) external {
        require(TxVerifier == address(0), "Fusion: already initialized");
        require(GasTank == address(0), "Fusion: already initialized");

        setupTrustedForwarder(_forwarder);
        TxVerifier = _txVerifier;
        GasTank = _gasTank;
        TxHash = _txHash;

        emit SetupFusion(_txVerifier, _forwarder, _gasTank, _txHash);
    }

    /**
     * @notice Executes a transaction
     * @param _proof The zk-SNARK proof
     * @param txData call to perform
     */
    function executeTx(
        bytes calldata _proof,
        Transaction.TransactionData calldata txData
    ) public payable notTrustedForwarder returns (bool success) {
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
                    0
                ),
                TxHash,
                TxVerifier,
                address(0), // 0x0 as the verifying address
                msg.sender
            ),
            "Fusion: invalid proof"
        );

        // Execute the call
        success = execute(
            txData.to,
            txData.value,
            txData.data,
            txData.operation,
            gasleft()
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
    ) public payable notTrustedForwarder {
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
                    0
                ),
                TxHash,
                TxVerifier,
                address(0), // 0x0 as the verifying address
                msg.sender
            ),
            "Fusion: invalid proof"
        );

        // Execute the batch call
        batchExecute(transactions, gasleft());
    }

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
    ) public payable onlyTrustedForwarder {
        // Verifying the proof
        require(
            verify(
                _proof,
                Transaction.getTxHash(
                    txData,
                    _useNonce(),
                    getChainId(),
                    token,
                    gasPrice,
                    baseGas
                ),
                TxHash,
                TxVerifier,
                from,
                tx.origin
            ),
            "Fusion: invalid proof"
        );

        // Check if the balance is sufficient
        require(
            checkBalance(token, estimatedFees),
            "Fusion: insufficient balance"
        );

        uint256 startGas = gasleft();

        require(
            execute(
                txData.to,
                txData.value,
                txData.data,
                txData.operation,
                gasleft()
            ),
            "Fusion: execution failed"
        );

        chargeFees(startGas, gasPrice, baseGas, GasTank, token);
    }

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
    ) public payable onlyTrustedForwarder {
        // Verifying the proof
        require(
            verify(
                _proof,
                Transaction.getTxBatchHash(
                    transactions,
                    _useNonce(),
                    getChainId(),
                    token,
                    gasPrice,
                    baseGas
                ),
                TxHash,
                TxVerifier,
                from,
                tx.origin
            ),
            "Fusion: invalid proof"
        );

        // Check if the balance is sufficient
        require(
            checkBalance(token, estimatedFees),
            "Fusion: insufficient balance"
        );

        uint256 startGas = gasleft();

        batchExecute(transactions, gasleft());

        chargeFees(startGas, gasPrice, baseGas, GasTank, token);
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
        if (
            verify(
                _signature,
                _hash,
                TxHash,
                TxVerifier,
                address(0),
                address(this)
            )
        ) {
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
