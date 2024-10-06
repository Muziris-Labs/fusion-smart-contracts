// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

/**
 * @title OpenBatchExecutor - Allows to execute a batch of transactions in a single transaction.
 * @author Anoy Roy Chowdhury - <anoy@valerium.id>
 */

contract OpenBatchTransactions {
    struct Transaction {
        address to;
        uint256 value;
        bytes data;
    }

    /**
     * @notice Executes a batch of transactions in a single transaction.
     * @param transactions The transactions to execute. The array must not be empty.
     */
    function executeBatch(Transaction[] memory transactions) public payable {
        uint256 totalValue = 0;

        for (uint i = 0; i < transactions.length; i++) {
            Transaction memory txn = transactions[i];
            totalValue += txn.value;

            require(
                address(this).balance >= txn.value,
                "Insufficient balance for transaction"
            );

            (bool success, ) = txn.to.call{value: txn.value}(txn.data);
            require(success, "Transaction failed");
        }

        require(
            msg.value >= totalValue,
            "Insufficient ETH sent for all transactions"
        );

        // Return any excess ETH
        uint256 remainingBalance = address(this).balance;
        if (remainingBalance > 0) {
            payable(msg.sender).transfer(remainingBalance);
        }
    }

    // Allow the contract to receive ETH
    receive() external payable {}
}
