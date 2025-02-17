// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

import {Enum} from "./Enum.sol";

/**
 * @title Transaction - Library for handling transactions in Fusion Wallet
 * @author Anoy Roy Chowdhury - <anoy@valerium.id>
 */
library Transaction {
    struct TransactionData {
        address to;
        uint256 value;
        bytes data;
        Enum.Operation operation;
        uint256 gasLimit;
    }

    /**
     * @notice Encode the transaction data with nonce
     * @param _tx  The transaction data
     * @param _nonce The nonce of the Fusion Wallet
     * @param _chainId The chain id of the network
     * @param _token The token address
     * @param _gasPrice The gas price
     * @param _baseGas The base gas
     */
    function encodeWithNonce(
        TransactionData memory _tx,
        uint256 _nonce,
        uint256 _chainId,
        address _token,
        uint256 _gasPrice,
        uint256 _baseGas,
        uint48 _deadline
    ) internal pure returns (bytes memory) {
        return
            abi.encode(
                _tx.to,
                _tx.value,
                _tx.data,
                uint8(_tx.operation),
                _nonce,
                _chainId,
                _token,
                _gasPrice,
                _baseGas,
                _deadline,
                _tx.gasLimit
            );
    }

    /**
     * @notice Get the hash of a transaction
     * @param _tx  The transaction data
     * @param _nonce  The nonce of the Fusion Wallet
     * @param _chainId  The chain id of the network
     * @param _token The token address
     * @param _gasPrice The gas price
     * @param _baseGas The base gas
     */
    function getTxHash(
        TransactionData memory _tx,
        uint256 _nonce,
        uint256 _chainId,
        address _token,
        uint256 _gasPrice,
        uint256 _baseGas,
        uint48 _deadline
    ) internal pure returns (bytes32) {
        return
            keccak256(
                encodeWithNonce(
                    _tx,
                    _nonce,
                    _chainId,
                    _token,
                    _gasPrice,
                    _baseGas,
                    _deadline
                )
            );
    }

    /**
     * @notice Get the hash of a batch of transactions
     * @param _txs All the transactions in the batch
     * @param _nonce The nonce of the Fusion Wallet
     * @param _chainId The chain id of the network
     * @param _token The token address
     * @param _gasPrice The gas price
     * @param _baseGas The base gas
     */
    function getTxBatchHash(
        TransactionData[] memory _txs,
        uint256 _nonce,
        uint256 _chainId,
        address _token,
        uint256 _gasPrice,
        uint256 _baseGas,
        uint48 _deadline
    ) internal pure returns (bytes32) {
        bytes memory txsData;
        for (uint256 i = 0; i < _txs.length; i++) {
            txsData = abi.encodePacked(
                txsData,
                encodeWithNonce(
                    _txs[i],
                    _nonce,
                    _chainId,
                    _token,
                    _gasPrice,
                    _baseGas,
                    _deadline
                )
            );
        }
        return keccak256(txsData);
    }
}
