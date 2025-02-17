// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

import "./FusionProxy.sol";
import "../external/FusionContext.sol";
import "../base/Verifier.sol";
import "../libraries/Conversion.sol";
import "../interfaces/IFusion.sol";
import "../libraries/Conversion.sol";

/**
 * @title Fusion Proxy Factory - Allows to create a new proxy contract and execute a message call to the new proxy within one transaction.
 * @author Anoy Roy Chowdhury - <anoy@valerium.id>
 */

contract FusionProxyFactory {
    event ProxyCreation(FusionProxy indexed proxy, address singleton);

    /// @dev Allows to retrieve the creation code used for the Proxy deployment. With this it is easily possible to calculate predicted address.
    function proxyCreationCode() public pure returns (bytes memory) {
        return type(FusionProxy).creationCode;
    }

    /**
     * @notice Internal method to create a new proxy contract using CREATE2.
     * @param Singleton Address of the singleton contract.
     * @param TxHash The common public input for proof verification.
     * @param TxVerifier Address of the TxVerifier contract.
     * @param TxHash The common public input for proof verification.
     * @param salt Create2 salt to use for calculating the address of the new proxy contract.
     * @param to Contract address for optional delegate call.
     * @param data Data payload for optional delegate call.
     * @return proxy Address of the new proxy contract.
     */
    function deployProxy(
        address Singleton,
        bytes32 TxHash,
        address TxVerifier,
        bytes32 salt,
        address to,
        bytes calldata data
    ) internal returns (FusionProxy proxy) {
        require(isContract(Singleton), "Singleton contract not deployed");

        bytes memory deploymentData = abi.encodePacked(
            type(FusionProxy).creationCode,
            uint256(uint160(Singleton))
        );
        // solhint-disable-next-line no-inline-assembly
        assembly {
            proxy := create2(
                0x0,
                add(0x20, deploymentData),
                mload(deploymentData),
                salt
            )
        }
        require(address(proxy) != address(0), "Create2 call failed");

        bytes memory initializer = getInitializer(TxVerifier, TxHash, to, data);

        // solhint-disable-next-line no-inline-assembly
        assembly {
            if eq(
                call(
                    gas(),
                    proxy,
                    0,
                    add(initializer, 0x20),
                    mload(initializer),
                    0,
                    0
                ),
                0
            ) {
                revert(0, 0)
            }
        }
    }

    /**
     * @notice Deploys a new proxy with the current singleton.
     * @param RegistryData Data payload for the registry.
     * @param to Contract address for optional delegate call.
     * @param data Data payload for optional delegate call.
     */
    function createProxyWithTxHash(
        bytes calldata RegistryData,
        address to,
        bytes calldata data
    ) public returns (FusionProxy proxy) {
        (address Singleton, bytes32 TxHash, address _txVerifier) = abi.decode(
            RegistryData,
            (address, bytes32, address)
        );

        proxy = _createProxyWithTxHash(
            Singleton,
            TxHash,
            _txVerifier,
            to,
            data
        );
    }

    /**
     * @notice Deploys a new proxy with `_singleton` singleton.
     * @param _singleton Address of the singleton contract.
     * @param _txHash The common public input for proof verification.
     * @param _txVerifier Address of the TxVerifier contract.
     * @param to Contract address for optional delegate call.
     * @param data Data payload for optional delegate call.
     * @dev The domain name is used to calculate the salt for the CREATE2 call.
     */
    function _createProxyWithTxHash(
        address _singleton,
        bytes32 _txHash,
        address _txVerifier,
        address to,
        bytes calldata data
    ) internal returns (FusionProxy proxy) {
        // If the domain changes the proxy address should change too.
        bytes32 salt = keccak256(abi.encodePacked(_txHash, _txVerifier));

        proxy = deployProxy(_singleton, _txHash, _txVerifier, salt, to, data);

        emit ProxyCreation(proxy, _singleton);
    }

    /**
     * @notice Returns true if `account` is a contract.
     * @dev This function will return false if invoked during the constructor of a contract,
     *      as the code is not actually created until after the constructor finishes.
     * @param account The address being queried
     * @return True if `account` is a contract
     */
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @notice Returns the initializer for the Fusion contract.
     * @param _txVerifier  The address of the TxVerifier contract.
     * @param _txHash The common public input for proof verification.
     * @param _to Contract address for optional delegate call.
     * @param _data Data payload for optional delegate call.
     */
    function getInitializer(
        address _txVerifier,
        bytes32 _txHash,
        address _to,
        bytes calldata _data
    ) internal pure returns (bytes memory) {
        return
            abi.encodeWithSelector(
                IFusion.setupFusion.selector,
                _txVerifier,
                _txHash,
                _to,
                _data
            );
    }
}
