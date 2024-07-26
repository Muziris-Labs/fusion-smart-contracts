// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

import "./ExecuteHandler.sol";
import "../libraries/Forwarder.sol";

/**
 * @title Fusion Forwarder - Handles the execution of transactions and batch transactions on Fusion Wallet
 * @author Anoy Roy Chowdhury - <anoy@valerium.id>
 * @notice Executes transactions and batch transactions on Fusion Wallet
 * @notice This contract is specifically designed to be used with the Fusion Wallet.
 *         Some function may not work as expected if used with other wallets.
 */

contract FusionForwarder is ExecuteHandler {
    // Initializing the EIP712 Domain Separator
    constructor(
        string memory name,
        string memory version
    ) ExecuteHandler(name, version) {}

    /**
     * @notice Executes a transaction using the provided data
     * @param request The ExecuteData Request
     * @param token The token address
     * @param gasPrice The gas price
     * @param baseGas The base gas
     * @param estimatedFees The estimated fees
     */
    function execute(
        Forwarder.ForwardExecuteData calldata request,
        address token,
        uint256 gasPrice,
        uint256 baseGas,
        uint256 estimatedFees
    ) public payable virtual {
        _execute(request, token, gasPrice, baseGas, estimatedFees, true);
    }

    /**
     * @notice Executes a batch of transactions using the provided data
     * @param request The ExecuteBatchData Request
     * @param token The token address
     * @param gasPrice The gas price
     * @param baseGas The base gas
     * @param estimatedFees The estimated fees
     */
    function executeBatch(
        Forwarder.ForwardExecuteBatchData calldata request,
        address token,
        uint256 gasPrice,
        uint256 baseGas,
        uint256 estimatedFees
    ) public payable virtual {
        _executeBatch(request, token, gasPrice, baseGas, estimatedFees, true);
    }
}
