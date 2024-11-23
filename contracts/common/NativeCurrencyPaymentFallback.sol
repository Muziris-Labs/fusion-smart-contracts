// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

/**
 * @title NativeCurrencyPaymentFallback - A contract that has a fallback to accept native currency payments.
 * @author Anoy Roy Chowdhury <anoy@valerium.id>
 */
abstract contract NativeCurrencyPaymentFallback {
    event FusionReceived(address indexed sender, uint256 value);

    /**
     * @notice Receive function accepts native currency transactions.
     * @dev Emits an event with sender and received value.
     */
    receive() external payable {
        emit FusionReceived(msg.sender, msg.value);
    }
}
