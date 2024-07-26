// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

import "./ExecuteHandler.sol";
import "../libraries/Forwarder.sol";

contract FusionForwarder is ExecuteHandler {
    constructor(
        string memory name,
        string memory version
    ) ExecuteHandler(name, version) {}

    function execute(
        Forwarder.ForwardExecuteData calldata request,
        address token,
        uint256 gasPrice,
        uint256 baseGas,
        uint256 estimatedFees
    ) public payable virtual {
        _execute(request, token, gasPrice, baseGas, estimatedFees, true);
    }

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
