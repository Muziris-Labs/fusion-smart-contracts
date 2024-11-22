// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Forwarder - Collection of structs and functions used in Fusion forwarders.
 * @author Anoy Roy Chowdhury - <anoy@valerium.id?>
 */

import {Enum} from "./Enum.sol";
import {Transaction} from "./Transaction.sol";
import "../external/Fusion2771Context.sol";

library Forwarder {
    struct ForwardExecuteData {
        address from;
        address recipient;
        uint48 deadline;
        uint256 gas;
        bytes proof;
        Transaction.TransactionData txData;
        bytes signature;
    }

    bytes32 internal constant TRANSACTION_TYPEHASH =
        keccak256(
            "Transaction(address to,uint256 value,bytes data,uint8 operation)"
        );

    bytes32 internal constant FORWARD_EXECUTE_TYPEHASH =
        keccak256(
            "ForwardExecute(address from,address recipient,uint256 deadline,uint256 gas,bytes proof,Transaction txData)Transaction(address to,uint256 value,bytes data,uint8 operation)"
        );

    struct ForwardExecuteBatchData {
        address from;
        address recipient;
        uint48 deadline;
        uint256 gas;
        bytes proof;
        Transaction.TransactionData[] txDatas;
        bytes signature;
    }

    bytes32 internal constant FORWARD_EXECUTE_BATCH_TYPEHASH =
        keccak256(
            "ForwardExecuteBatch(address from,address recipient,uint256 deadline,uint256 gas,bytes proof,Transaction[] txDatas)Transaction(address to,uint256 value,bytes data,uint8 operation)"
        );

    /**
     * @notice Hashes the transaction data
     * @param _tx The transaction data
     */
    function hashTransaction(
        Transaction.TransactionData memory _tx
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    TRANSACTION_TYPEHASH,
                    _tx.to,
                    _tx.value,
                    keccak256(_tx.data),
                    uint8(_tx.operation)
                )
            );
    }

    /**
     * @notice Hashes the forward execute data
     * @param _data The forward execute data
     */
    function hashForwardExecute(
        ForwardExecuteData memory _data
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    FORWARD_EXECUTE_TYPEHASH,
                    _data.from,
                    _data.recipient,
                    _data.deadline,
                    _data.gas,
                    keccak256(_data.proof),
                    hashTransaction(_data.txData)
                )
            );
    }

    /**
     * @notice Hashes the forward execute batch data
     * @param _data The forward execute batch data
     */
    function hashForwardExecuteBatch(
        ForwardExecuteBatchData memory _data
    ) internal pure returns (bytes32) {
        bytes memory txsData;
        for (uint256 i = 0; i < _data.txDatas.length; i++) {
            txsData = abi.encodePacked(
                txsData,
                hashTransaction(_data.txDatas[i])
            );
        }
        return
            keccak256(
                abi.encode(
                    FORWARD_EXECUTE_BATCH_TYPEHASH,
                    _data.from,
                    _data.recipient,
                    _data.deadline,
                    _data.gas,
                    _data.proof,
                    keccak256(txsData)
                )
            );
    }

    /**
     * Checks if the forwarder is trusted by the target
     * @param target address of the target contract
     */
    function _isTrustedByTarget(address target) internal view returns (bool) {
        bytes memory encodedParams = abi.encodeCall(
            Fusion2771Context.isTrustedForwarder,
            (address(this))
        );

        bool success;
        uint256 returnSize;
        uint256 returnValue;
        assembly {
            success := staticcall(
                gas(),
                target,
                add(encodedParams, 0x20),
                mload(encodedParams),
                0,
                0x20
            )
            returnSize := returndatasize()
            returnValue := mload(0)
        }

        return success && returnSize >= 0x20 && returnValue > 0;
    }

    /**
     * Checks if the gas forwarded is sufficient
     * @param gasLeft gas left after the forwarding
     * @param requestGas gas requested for the forwarding
     * @dev To avoid insufficient gas griefing attacks, as referenced in https://ronan.eth.limo/blog/ethereum-gas-dangers/
     */
    function _checkForwardedGas(
        uint256 gasLeft,
        uint256 requestGas
    ) internal pure {
        if (gasLeft < requestGas / 63) {
            assembly {
                invalid()
            }
        }
    }
}
