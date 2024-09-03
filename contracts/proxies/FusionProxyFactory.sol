// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

import "./FusionProxy.sol";
import "./IProxyCreationCallback.sol";
import "../external/Fusion2771Context.sol";
import "../base/Verifier.sol";
import "../libraries/Conversion.sol";
import "../interfaces/IFusion.sol";
import "../cross-chain/WormholeManager.sol";
import "../libraries/Conversion.sol";

/**
 * @title Fusion Proxy Factory - Allows to create a new proxy contract and execute a message call to the new proxy within one transaction.
 * @author Anoy Roy Chowdhury - <anoy@valerium.id>
 */

contract FusionProxyFactory is WormholeManager, Verifier {
    event ProxyCreation(FusionProxy indexed proxy, address singleton);

    event SingletonUpdated(address singleton);

    // The address of the account that initially created the factory contract.
    address private GenesisAddress;

    // The address of the current singleton contract used as the master copy for proxy contracts.
    address private CurrentSingleton;

    // The address of the base fusion proxy factory contract.
    address private baseProxyFactory;

    // The base chain id.
    uint256 private baseChainId;

    // The current chain id.
    uint256 private currentChainId;

    // The constructor sets the initial singleton contract address, the GenesisAddress, baseProxyFactory, wormholeRelayer and baseChainId.
    constructor(
        address CurrentSingleton_,
        address _baseProxyFactory,
        uint256 baseChainId_,
        address wormholeRelayer,
        uint256 currentChainId_
    ) WormholeManager(wormholeRelayer) {
        GenesisAddress = msg.sender;
        CurrentSingleton = CurrentSingleton_;
        baseProxyFactory = _baseProxyFactory;
        baseChainId = baseChainId_;
        currentChainId = currentChainId_;
    }

    /**
     * @notice Returns if the contract is deployed on the base chain.
     */
    function IsBaseChain() public view returns (bool) {
        return baseChainId == currentChainId;
    }

    /**
     * @notice  Modifier to restrict the execution of a function to the base chain.
     */
    modifier onlyBase() {
        require(IsBaseChain(), "Only the base chain can call this function");
        _;
    }

    /**
     * @notice  Modifier to restrict the execution of a function to the non-base chain.
     */
    modifier notBase() {
        require(!IsBaseChain(), "Cannot call this function on the base chain");
        _;
    }

    /// @dev Allows to retrieve the creation code used for the Proxy deployment. With this it is easily possible to calculate predicted address.
    function proxyCreationCode() public pure returns (bytes memory) {
        return type(FusionProxy).creationCode;
    }

    /**
     * @notice Internal method to create a new proxy contract using CREATE2. Optionally executes an initializer call to a new proxy.
     * @param initializer (Optional) Payload for a message call to be sent to a new proxy contract.
     * @param salt Create2 salt to use for calculating the address of the new proxy contract.
     * @return proxy Address of the new proxy contract.
     */
    function deployProxy(
        bytes memory initializer,
        bytes32 salt
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

        if (initializer.length > 0) {
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
    }

    /**
     * @notice Updates the address of the current singleton contract used as the master copy for proxy contracts.
     * @dev Only the Genesis Address can update the Singleton.
     * @param _singleton Address of the current singleton contract.
     */
    function updateSingleton(address _singleton) external {
        require(
            msg.sender == GenesisAddress,
            "Only the Genesis Address can update the Singleton"
        );
        CurrentSingleton = _singleton;
        emit SingletonUpdated(_singleton);
    }

    /**
     * @notice Deploys a new proxy with the current singleton. Optionally executes an initializer call to a new proxy.
     * @param domain  The domain name of the new proxy contract.
     * @param initializer Payload for a message call to be sent to a new proxy contract.
     */
    function createProxyWithDomain(
        string memory domain,
        bytes memory initializer
    ) public onlyBase returns (FusionProxy proxy) {
        proxy = _createProxyWithDomain(domain, initializer);
    }

    /**
     * @notice Deploys a new proxy with `_singleton` singleton. Optionally executes an initializer call to a new proxy.
     * @param domain The domain name of the new proxy contract.
     * @param initializer Payload for a message call to be sent to a new proxy contract.
     * @dev The domain name is used to calculate the salt for the CREATE2 call.
     */
    function _createProxyWithDomain(
        string memory domain,
        bytes memory initializer
    ) internal returns (FusionProxy proxy) {
        // If the domain changes the proxy address should change too.
        bytes32 salt = keccak256(
            abi.encodePacked(keccak256(abi.encodePacked(domain)))
        );
        proxy = deployProxy(initializer, salt);

        emit ProxyCreation(proxy, CurrentSingleton);
    }

    /**
     * @notice Deploys a new proxy with the current singleton on the child chain through Wormhole. Optionally executes an initializer call to a new proxy.
     * @param proof The proof to verify the message.
     * @param domain The domain name of the new proxy contract.
     * @param initializer Payload for a message call to be sent to a new proxy contract.
     * @param targetChain The chain id of the target chain.
     * @param targetAddress The address of the target contract.
     */
    function createProxyWithWormhole(
        bytes calldata proof,
        string memory domain,
        bytes memory initializer,
        uint16 targetChain,
        address targetAddress,
        uint256 gasLimit
    ) external payable onlyBase {
        require(
            domainExists(domain),
            "FusionProxyFactory: Domain does not exist"
        );

        {
            IFusion fusion = IFusion(getFusionProxy(domain));
            bytes32 txHash = fusion.TxHash();
            address txVerifier = fusion.TxVerifier();

            require(
                verify(
                    proof,
                    domain,
                    initializer,
                    targetChain,
                    targetAddress,
                    address(this),
                    msg.sender,
                    txHash,
                    txVerifier
                ),
                "FusionProxyFactory: Invalid proof"
            );
        }

        sendCrossChainDeployment(
            uint16(targetChain),
            targetAddress,
            domain,
            initializer,
            uint16(currentChainId),
            GenesisAddress,
            gasLimit
        );
    }

    /**
     * @notice Retrieves the FusionProxy contract address for a given domain.
     * @param domain Domain name.
     * @return fusionProxy FusionProxy contract address.
     */
    function getFusionProxy(
        string memory domain
    ) public view returns (address fusionProxy) {
        bytes32 salt = keccak256(
            abi.encodePacked(keccak256(abi.encodePacked(domain)))
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

        if (isContract(fusion)) {
            return fusion;
        } else {
            return address(0);
        }
    }

    /**
     * @notice Checks if a domain exists.
     * @param domain Domain name.
     * @return exists Boolean value indicating if the domain exists.
     */
    function domainExists(
        string memory domain
    ) public view returns (bool exists) {
        return getFusionProxy(domain) != address(0);
    }

    /**
     * @notice Verifies the proof.
     * @param proof The proof to verify the message.
     * @param domain  The domain name of the new proxy contract.
     * @param intializer  Payload for a message call to be sent to a new proxy contract.
     * @param targetChain  The chain id of the target chain.
     * @param targetAddress  The address of the target contract.
     * @param _verifyingAddress  The address of the contract verifying the proof.
     * @param _signingAddress The address of the contract signing the message.
     * @param txHash The hash of the transaction.
     * @param txVerifier The address of the verifier contract.
     */
    function verify(
        bytes calldata proof,
        string memory domain,
        bytes memory intializer,
        uint16 targetChain,
        address targetAddress,
        address _verifyingAddress,
        address _signingAddress,
        bytes32 txHash,
        address txVerifier
    ) internal view returns (bool) {
        bytes32 messageHash = getDeployHash(
            domain,
            intializer,
            targetChain,
            targetAddress
        );

        bytes32[] memory publicInputs = Conversion.convertToInputs(
            messageHash,
            txHash,
            _verifyingAddress,
            _signingAddress
        );
        return verifyProof(proof, publicInputs, txVerifier);
    }

    /**
     * @notice Receives messages from the base Proxy Factory through Wormhole.
     * @param payload  The payload of the message.
     * @param sourceAddress  The address of the source contract.
     * @param sourceChain  The chain id of the source chain.
     */
    function receiveWormholeMessages(
        bytes memory payload,
        bytes[] memory, // additionalVaas
        bytes32 sourceAddress,
        uint16 sourceChain,
        bytes32 // delivery hash
    ) public payable override onlyWormholeRelayer notBase {
        require(
            sourceChain == baseChainId,
            "FusionProxyFactory: Invalid source chain"
        );

        require(
            address(uint160(uint256(sourceAddress))) == baseProxyFactory,
            "FusionProxyFactory: Invalid source address"
        );

        require(payload.length > 0, "FusionProxyFactory: Invalid payload");

        (string memory domain, bytes memory initializer) = abi.decode(
            payload,
            (string, bytes)
        );

        FusionProxy proxy = _createProxyWithDomain(domain, initializer);

        emit ProxyCreation(proxy, CurrentSingleton);
    }

    /**
     * @notice Returns the hash of the message to be signed.
     * @param domain  The domain name of the new proxy contract.
     * @param initializer  Payload for a message call to be sent to a new proxy contract.
     * @param targetChain  The chain id of the target chain.
     * @param targetAddress  The address of the target contract.
     */
    function getDeployHash(
        string memory domain,
        bytes memory initializer,
        uint16 targetChain,
        address targetAddress
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    domain,
                    initializer,
                    targetChain,
                    targetAddress
                )
            );
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
     * @notice Allows the Genesis Address to transfer ownership.
     * @param newGenesis Address of the new Genesis Address.
     */
    function transferGenesis(address newGenesis) external {
        require(
            msg.sender == GenesisAddress,
            "Only the Genesis Address can transfer ownership"
        );
        GenesisAddress = newGenesis;
    }
}
