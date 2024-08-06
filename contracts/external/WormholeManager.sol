// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.1) (utils/Context.sol)

pragma solidity >=0.7.0 <0.9.0;

import "../interfaces/IWormholeRelayer.sol";
import "../interfaces/IWormholeReceiver.sol";

/**
 * @title WormholeManager - A contract that manages the wormhole between the base chain and the side chain.
 * @author Anoy Roy Chowdhury - <anoy@valerium.id>
 * @notice Manages the wormhole between the base chain and the side chain.
 */

abstract contract WormholeManager is IWormholeReceiver {
    // The address of the wormhole relayer
    IWormholeRelayer public immutable wormholeRelayer;

    // Initializing the wormhole relayer and gas limit
    constructor(address _wormholeRelayer) {
        wormholeRelayer = IWormholeRelayer(_wormholeRelayer);
    }

    // Modifier to check if the caller is the wormhole relayer
    modifier onlyWormholeRelayer() {
        require(
            msg.sender == address(wormholeRelayer),
            "Only the wormhole relayer can call this function"
        );
        _;
    }

    /**
     * @notice Quotes the cost of a cross-chain deployment
     * @param targetChain The chain to which the deployment is to be sent
     */
    function quoteCrossChainDeployment(
        uint16 targetChain,
        uint256 gas_limit
    ) public view returns (uint256 cost) {
        (cost, ) = wormholeRelayer.quoteEVMDeliveryPrice(
            targetChain,
            0,
            gas_limit
        );
    }

    /**
     * @notice Sends a cross-chain deployment
     * @param targetChain  The chain to which the deployment is to be sent
     * @param targetAddress  The address to which the deployment is to be sent
     * @param domain  The domain of the deployment
     * @param initializer  The initializer of the deployment
     * @param refundChain  The chain to which the refund is to be sent
     * @param refundAddress  The address to which the refund is to be sent
     */
    function sendCrossChainDeployment(
        uint16 targetChain,
        address targetAddress,
        string memory domain,
        bytes memory initializer,
        uint16 refundChain,
        address refundAddress,
        uint256 gas_limit
    ) internal {
        uint256 cost = quoteCrossChainDeployment(targetChain, gas_limit);
        require(msg.value == cost, "Invalid value sent");
        wormholeRelayer.sendPayloadToEvm{value: cost}(
            targetChain,
            targetAddress,
            abi.encode(domain, initializer), // payload
            0, // no receiver value needed since we're just passing a message
            gas_limit,
            refundChain,
            refundAddress
        );
    }
}
