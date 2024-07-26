// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

import "../proxies/FusionProxy.sol";
import "../proxies/IProxyCreationCallback.sol";

interface IFusionProxyFactory {
    event ProxyCreation(FusionProxy indexed proxy, address singleton);
    event SingletonUpdated(address singleton);

    // The address of the account that initially created the factory contract.
    function IsBaseChain() external view returns (bool);

    // The address of the current singleton contract used as the master copy for proxy contracts.
    function proxyCreationCode() external pure returns (bytes memory);

    // The address of the current singleton contract used as the master copy for proxy contracts.
    function updateSingleton(address _singleton) external;

    /**
     * @notice Deploys a new proxy with the current singleton. Optionally executes an initializer call to a new proxy.
     * @param domain  The domain name of the new proxy contract.
     * @param initializer Payload for a message call to be sent to a new proxy contract.
     */
    function createProxyWithDomain(
        string memory domain,
        bytes memory initializer
    ) external returns (FusionProxy proxy);

    /**
     * @notice Deploy a new proxy with `_singleton` singleton
     *         Optionally executes an initializer call to a new proxy and calls a specified callback address `callback`.
     * @param domain The domain name of the new proxy contract.
     * @param initializer Payload for a message call to be sent to a new proxy contract.
     * @param callback Callback that will be invoked after the new proxy contract has been successfully deployed and initialized.
     * @dev The domain name is used to calculate the salt for the CREATE2 call.
     */
    function createProxyWithCallback(
        string memory domain,
        bytes memory initializer,
        IProxyCreationCallback callback
    ) external returns (FusionProxy proxy);

    /**
     * @notice Retrieves the FusionProxy contract address for a given domain.
     * @param domain Domain name.
     * @return fusionProxy FusionProxy contract address.
     */
    function getFusionProxy(
        string memory domain
    ) external view returns (address fusionProxy);

    /**
     * @notice Checks if a domain exists.
     * @param domain Domain name
     */
    function domainExists(
        string memory domain
    ) external view returns (bool exists);

    /**
     * @notice Allows the Genesis Address to setup the forwarder.
     * @param forwarder Address of the forwarder contract.
     */
    function setupForwarder(address forwarder) external;

    /**
     * @notice Allows the Genesis Address to transfer ownership.
     * @param newGenesis Address of the new Genesis Address.
     */
    function transferGenesis(address newGenesis) external;
}
