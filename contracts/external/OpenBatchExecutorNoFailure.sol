// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

/**
 * @title OpenBatchExecutorNoFailure - Execute a batch of transactions in a single transaction without reverting on failure
 * @author Anoy Roy Chowdhury - <anoy@valerium.id>
 */

contract OpenBatchExecutorNoFailure {
    event TransactionResult(uint256 index, address to, bool success);

    struct Transaction {
        address to;
        uint256 value;
        bytes data;
    }

    /**
     * @notice Executes a batch of transactions in a single transaction.
     * @param transactions The transactions to execute. The array must not be empty.
     */
    function executeBatch(
        Transaction[] memory transactions
    ) public payable returns (bool[] memory results) {
        require(transactions.length > 0, "No transactions provided");

        uint256 totalValue = 0;
        results = new bool[](transactions.length); // Array to store the results

        for (uint256 i = 0; i < transactions.length; i++) {
            Transaction memory txn = transactions[i];
            totalValue += txn.value;

            require(
                address(this).balance >= txn.value,
                "Insufficient balance for transaction"
            );

            // Attempt to execute the transaction
            (bool success, ) = txn.to.call{value: txn.value}(txn.data);

            // Store the result
            results[i] = success;

            emit TransactionResult(i, txn.to, success);
        }

        require(
            msg.value >= totalValue,
            "Insufficient ETH sent for all transactions"
        );

        // Return any excess ETH to the sender
        uint256 remainingBalance = address(this).balance;
        if (remainingBalance > 0) {
            payable(msg.sender).transfer(remainingBalance);
        }
    }

    // Allow the contract to receive ETH
    receive() external payable {}
}
