// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;
import "./FusionProxy.sol";

/**
 * @title IProxyCreationCallback
 * @dev An interface for a contract that implements a callback function to be executed after the creation of a proxy instance.
 */

interface IProxyCreationCallback {
    /**
     * @dev Function to be called after the creation of a FusionProxy instance.
     * @param proxy The newly created FusionProxy instance.
     * @param _singleton The address of the singleton contract used to create the proxy.
     * @param initializer The initializer function call data.
     */
    function proxyCreated(
        FusionProxy proxy,
        address _singleton,
        bytes calldata initializer
    ) external;
}
