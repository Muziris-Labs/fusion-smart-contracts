// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

import {Enum} from "../libraries/Enum.sol";
import {Transaction} from "../libraries/Transaction.sol";

interface IFusion {
    event SetupFusion(
        address txVerifier,
        address forwarder,
        address gasTank,
        bytes32 txHash
    );

    function VERSION() external view returns (string memory);

    function TxVerifier() external view returns (address);

    function TxHash() external view returns (bytes32);

    function GasTank() external view returns (address);

    function setupFusion(
        address _txVerifier,
        address _forwarder,
        address _gasTank,
        bytes32 _txHash
    ) external;

    function executeTx(
        bytes calldata _proof,
        Transaction.TransactionData calldata txData
    ) external payable returns (bool success);

    function executeBatchTx(
        bytes calldata _proof,
        Transaction.TransactionData[] calldata transactions
    ) external payable;

    function executeTxWithForwarder(
        bytes calldata _proof,
        Transaction.TransactionData calldata txData,
        address from,
        address token,
        uint256 gasPrice,
        uint256 baseGas,
        uint256 estimatedFees
    ) external payable;

    function executeBatchTxWithForwarder(
        bytes calldata _proof,
        Transaction.TransactionData[] calldata transactions,
        address from,
        address token,
        uint256 gasPrice,
        uint256 baseGas,
        uint256 estimatedFees
    ) external payable;

    function isValidSignature(
        bytes32 _hash,
        bytes calldata _signature
    ) external view returns (bytes4 magicValue);

    function getNonce() external view returns (uint256);
}
