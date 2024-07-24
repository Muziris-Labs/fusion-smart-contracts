// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

import {Enum} from "../libraries/Enum.sol";

/**
 * @title Executor - A contract that can execute transactions
 * @author Anoy Roy Chowdhury - <anoy@valerium.id>
 */
abstract contract Executor {
    struct Transaction {
        address to;
        uint256 value;
        bytes data;
        Enum.Operation operation;
    }

    /**
     * @notice Executes a call with provided parameters.
     * @dev This method doesn't perform any sanity check of the transaction, such as:
     *      - if the contract at `to` address has code or not
     *      It is the responsibility of the caller to perform such checks.
     * @param to Destination address.
     * @param value Ether value.
     * @param data Data payload.
     * @return success boolean flag indicating if the call succeeded.
     */
    function execute(
        address to,
        uint256 value,
        bytes memory data,
        Enum.Operation operation,
        uint256 txGas
    ) internal returns (bool success) {
        if (operation == Enum.Operation.DelegateCall) {
            /* solhint-disable no-inline-assembly */
            assembly {
                success := delegatecall(
                    txGas,
                    to,
                    add(data, 0x20),
                    mload(data),
                    0,
                    0
                )
            }
            /* solhint-enable no-inline-assembly */
        } else {
            /* solhint-disable no-inline-assembly */
            assembly {
                success := call(
                    txGas,
                    to,
                    value,
                    add(data, 0x20),
                    mload(data),
                    0,
                    0
                )
            }
            /* solhint-enable no-inline-assembly */
        }
    }

    /**
     * @notice Executes a batch of transactions.
     * @dev This method doesn't perform any sanity check of the transactions, such as:
     *      - if the contract at `to` address has code or not
     *      It is the responsibility of the caller to perform such checks.
     * @param transactions Array of Transaction objects.
     * @param txGas Gas limit for each transaction.
     */
    function batchExecute(
        Transaction[] memory transactions,
        uint256 txGas
    ) internal {
        for (uint256 i = 0; i < transactions.length; i++) {
            bool success = execute(
                transactions[i].to,
                transactions[i].value,
                transactions[i].data,
                transactions[i].operation,
                txGas
            );

            require(success, "Fusion: batch execution failed");
        }
    }
}
