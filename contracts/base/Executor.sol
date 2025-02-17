// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

import {Enum} from "../libraries/Enum.sol";
import {Transaction} from "../libraries/Transaction.sol";

/**
 * @title Executor - A contract that can execute transactions
 * @author Anoy Roy Chowdhury - <anoy@valerium.id>
 */
abstract contract Executor {
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
        uint256 gasLeft;

        if (operation == Enum.Operation.DelegateCall) {
            /* solhint-disable no-inline-assembly */
            assembly ("memory-safe") {
                success := delegatecall(
                    txGas,
                    to,
                    add(data, 0x20),
                    mload(data),
                    0,
                    0
                )

                gasLeft := gas()
            }
            /* solhint-enable no-inline-assembly */
        } else {
            /* solhint-disable no-inline-assembly */
            assembly ("memory-safe") {
                success := call(
                    txGas,
                    to,
                    value,
                    add(data, 0x20),
                    mload(data),
                    0,
                    0
                )

                gasLeft := gas()
            }
            /* solhint-enable no-inline-assembly */
        }

        // Check if the gas left is less than 1/63 of the initial gas
        // To avoid insufficient gas griefing attacks, as referenced in https://ronan.eth.limo/blog/ethereum-gas-dangers/
        if (gasLeft < txGas / 63) {
            assembly ("memory-safe") {
                invalid()
            }
        }
    }

    /**
     * @notice Executes a batch of transactions.
     * @dev This method doesn't perform any sanity check of the transactions, such as:
     *      - if the contract at `to` address has code or not
     *      It is the responsibility of the caller to perform such checks.
     * @param transactions Array of Transaction objects.
     */
    function batchExecute(
        Transaction.TransactionData[] memory transactions
    ) internal {
        for (uint256 i = 0; i < transactions.length; i++) {
            bool success = execute(
                transactions[i].to,
                transactions[i].value,
                transactions[i].data,
                transactions[i].operation,
                transactions[i].gasLimit
            );

            require(success, "Fusion: batch execution failed");
        }
    }
}
