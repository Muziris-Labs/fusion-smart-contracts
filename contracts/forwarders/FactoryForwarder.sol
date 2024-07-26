// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "../external/Fusion2771Context.sol";
import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import "@openzeppelin/contracts/utils/Nonces.sol";
import "./ServerHandler.sol";
import "../interfaces/IFusionProxyFactory.sol";
import "../libraries/Forwarder.sol";

/**
 * @title Factory Forwarder - Handles the deployment of proxy contracts
 * @author Anoy Roy Chowdhury - <anoy@valerium.id>
 * @notice This contract is specifically designed to be used with the Fusion Factory Contract,
 *         and some function may not work as expected if used with other contracts. To be used
 *         to deploy Fusion Wallet through Fusion Factory Contract.
 */

contract FactoryForwarder is EIP712, Nonces, ServerHandler {
    using ECDSA for bytes32;

    // isBase is used to check if the contract is in base chain
    bool immutable isBase;

    // Initializing the EIP712 Domain Separator
    constructor(
        string memory name,
        string memory version,
        bool _isBase
    ) EIP712(name, version) {
        isBase = _isBase;
    }

    modifier checkBase(
        bytes calldata serverProof,
        bytes4 domain,
        address from
    ) {
        if (!isBase) {
            require(
                verify(serverProof, serverHash, ServerVerifier, domain, from),
                "FusionForwarder: invalid serverProof"
            );
        }
        _;
    }

    /**
     * @notice Deploys a proxy contract using the provided data
     * @param serverProof The server proof
     * @param request The forwarder request
     */
    function execute(
        bytes calldata serverProof,
        Forwarder.ForwardDeployData calldata request
    )
        public
        payable
        virtual
        checkBase(
            serverProof,
            bytes4(keccak256(abi.encodePacked(request.domain))),
            request.from
        )
    {
        _deploy(request, true);
    }

    /**
     * @notice Deploys a proxy contract using the provided data
     * @param request  The deploy request
     * @param requireValidRequest if true, the request must be valid
     */
    function _deploy(
        Forwarder.ForwardDeployData calldata request,
        bool requireValidRequest
    ) internal virtual {
        (
            bool isTrustedForwarder,
            bool active,
            bool signerMatch,
            address signer
        ) = _validate(request);

        if (requireValidRequest) {
            if (!isTrustedForwarder) {
                revert("FactoryForwarder: untrusted forwarder");
            }

            if (!active) {
                revert("FactoryForwarder: request expired");
            }

            if (!signerMatch) {
                revert("FactoryForwarder: invalid signer");
            }
        }

        // Ignore an invalid request because requireValidRequest = false
        if (isTrustedForwarder && signerMatch && active) {
            // Nonce should be used before the call to prevent reusing by reentrancy
            _useNonce(signer);

            (bool success, ) = address(request.recipient).call{
                gas: request.gas
            }(
                abi.encodeWithSelector(
                    IFusionProxyFactory.createProxyWithDomain.selector,
                    request.domain,
                    request.initializer
                )
            );

            Forwarder._checkForwardedGas(gasleft(), request.gas);

            if (!success) {
                revert("FactoryForwarder: deployment failed");
            }
        }
    }

    /**
     * @notice Validates the forwarder request
     * @param request The deploy request
     * @return isTrustedForwarder If the forwarder is trusted
     * @return active If the request is active
     * @return signerMatch If the signer matches
     * @return signer The signer address
     */
    function _validate(
        Forwarder.ForwardDeployData calldata request
    )
        internal
        view
        virtual
        returns (
            bool isTrustedForwarder,
            bool active,
            bool signerMatch,
            address signer
        )
    {
        (bool isValid, address recovered) = _recoverForwardSigner(request);

        return (
            Forwarder._isTrustedByTarget(request.recipient),
            request.deadline >= block.timestamp,
            isValid && recovered == request.from,
            recovered
        );
    }

    /**
     * @notice Recovers the signer of the forwarder request
     * @param request  The deploy request
     * @return  isValid If the signature is valid
     * @return recovered The recovered signer
     */
    function _recoverForwardSigner(
        Forwarder.ForwardDeployData calldata request
    ) internal view virtual returns (bool, address) {
        (address recovered, ECDSA.RecoverError err, ) = _hashTypedDataV4(
            Forwarder.hashDeploy(request)
        ).tryRecover(request.signature);

        return (err == ECDSA.RecoverError.NoError, recovered);
    }
}
