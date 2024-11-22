// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

import "./FusionProxy.sol";
import "../external/Fusion2771Context.sol";
import "../base/Verifier.sol";
import "../libraries/Conversion.sol";
import "../interfaces/IFusion.sol";
import "../libraries/Conversion.sol";
import "../common/GenesisManager.sol";
import "./FusionAddressRegistry.sol";

/**
 * @title Fusion Proxy Factory - Allows to create a new proxy contract and execute a message call to the new proxy within one transaction.
 * @author Anoy Roy Chowdhury - <anoy@valerium.id>
 */

contract FusionProxyFactory is GenesisManager, FusionAddressRegistry {
    event ProxyCreation(FusionProxy indexed proxy, address singleton);

    event SingletonUpdated(address singleton);

    // The address of the current singleton contract used as the master copy for proxy contracts.
    address private CurrentSingleton;

    // The constructor sets the GenesisAddress and the current singleton contract.
    constructor(address CurrentSingleton_) {
        CurrentSingleton = CurrentSingleton_;
    }

    /// @dev Allows to retrieve the creation code used for the Proxy deployment. With this it is easily possible to calculate predicted address.
    function proxyCreationCode() public pure returns (bytes memory) {
        return type(FusionProxy).creationCode;
    }

    /**
     * @notice Internal method to create a new proxy contract using CREATE2.
     * @param TxHash The common public input for proof verification.
     * @param salt Create2 salt to use for calculating the address of the new proxy contract.
     * @param to Contract address for optional delegate call.
     * @param data Data payload for optional delegate call.
     * @return proxy Address of the new proxy contract.
     */
    function deployProxy(
        bytes32 TxHash,
        bytes32 salt,
        address to,
        bytes calldata data
    ) internal returns (FusionProxy proxy) {
        require(
            isContract(CurrentSingleton),
            "Singleton contract not deployed"
        );

        bytes memory deploymentData = abi.encodePacked(
            type(FusionProxy).creationCode
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

        proxy.setupSingleton(CurrentSingleton);

        bytes memory initializer = getInitializer(
            TxVerifier,
            FusionForwarder,
            GasTank,
            TxHash,
            to,
            data
        );

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
     * @notice Updates the address of the current singleton contract used as the master copy for proxy contracts.
     * @dev Only the Genesis Address can update the Singleton.
     * @param _singleton Address of the current singleton contract.
     */
    function updateSingleton(address _singleton) external onlyGenesis {
        CurrentSingleton = _singleton;
        emit SingletonUpdated(_singleton);
    }

    /**
     * @notice Deploys a new proxy with the current singleton.
     * @param TxHash The common public input for proof verification.
     * @param to Contract address for optional delegate call.
     * @param data Data payload for optional delegate call.
     */
    function createProxyWithTxHash(
        bytes32 TxHash,
        address to,
        bytes calldata data
    ) public returns (FusionProxy proxy) {
        proxy = _createProxyWithTxHash(TxHash, to, data);
    }

    /**
     * @notice Deploys a new proxy with `_singleton` singleton.
     * @param _txHash The common public input for proof verification.
     * @param to Contract address for optional delegate call.
     * @param data Data payload for optional delegate call.
     * @dev The domain name is used to calculate the salt for the CREATE2 call.
     */
    function _createProxyWithTxHash(
        bytes32 _txHash,
        address to,
        bytes calldata data
    ) internal returns (FusionProxy proxy) {
        // If the domain changes the proxy address should change too.
        bytes32 salt = keccak256(
            abi.encodePacked(keccak256(abi.encodePacked(_txHash)))
        );
        proxy = deployProxy(_txHash, salt, to, data);

        emit ProxyCreation(proxy, CurrentSingleton);
    }

    /**
     * @notice Retrieves the FusionProxy contract address for a given domain.
     * @param TxHash The common public input for proof verification.
     */
    function getFusionProxy(
        bytes32 TxHash
    ) public view returns (address fusionProxy) {
        bytes32 salt = keccak256(
            abi.encodePacked(keccak256(abi.encodePacked(TxHash)))
        );
        bytes memory deploymentData = abi.encodePacked(proxyCreationCode());

        // Calculate the address of the proxy contract using CREATE2
        bytes32 hash = keccak256(
            abi.encodePacked(
                bytes1(0xff),
                address(this),
                salt,
                keccak256(deploymentData)
            )
        );

        // Cast the hash to an address
        address fusion = address(uint160(uint256(hash)));

        return fusion;
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
     * @param _forwarder The address of the FusionForwarder contract.
     * @param _gasTank The address of the GasTank.
     * @param _txHash The common public input for proof verification.
     * @param _to Contract address for optional delegate call.
     * @param _data Data payload for optional delegate call.
     */
    function getInitializer(
        address _txVerifier,
        address _forwarder,
        address _gasTank,
        bytes32 _txHash,
        address _to,
        bytes calldata _data
    ) internal pure returns (bytes memory) {
        return
            abi.encodeWithSelector(
                IFusion.setupFusion.selector,
                _txVerifier,
                _forwarder,
                _gasTank,
                _txHash,
                _to,
                _data
            );
    }

    /**
     * @notice Setup function sets the initial Registry of the contract.
     * @param _txVerifier  The address of the TxVerifier contract.
     * @param _forwarder The address of the FusionForwarder contract.
     * @param _gasTank  The address of the GasTank.
     */
    function setupRegistry(
        address _txVerifier,
        address _forwarder,
        address _gasTank
    ) external onlyGenesis {
        _setupRegistry(_txVerifier, _forwarder, _gasTank);
    }

    /**
     * @notice Update the address in the Fusion Registry.
     * @param selector The Address to be updated.
     * @param newAddress The new address.
     */
    function updateRegistry(
        Selector selector,
        address newAddress
    ) external onlyGenesis {
        _updateRegistry(selector, newAddress);
    }
}
