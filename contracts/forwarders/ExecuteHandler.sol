// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import "@openzeppelin/contracts/utils/Nonces.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "../external/Fusion2771Context.sol";
import "../libraries/Forwarder.sol";
import "../interfaces/IFusion.sol";

/**
 * @title Execute Handler - Handles the execution of transactions and batch transactions on Fusion Wallet
 * @author Anoy Roy Chowdhury - <anoy@valerium.id>
 * @notice Executes transactions and batch transactions on Fusion Wallet
 */

abstract contract ExecuteHandler is EIP712, Nonces {
    using ECDSA for bytes32;

    // Initializing the EIP712 Domain Separator
    constructor(
        string memory name,
        string memory version
    ) EIP712(name, version) {}

    /**
     * @notice Executes a transaction using the provided data
     * @param request The forwarder request
     * @param token The token address
     * @param gasPrice The gas price
     * @param baseGas The base gas
     * @param estimatedFees The estimated fees
     * @param requireValidRequest If the request should be validated
     */
    function _execute(
        Forwarder.ForwardExecuteData calldata request,
        address token,
        uint256 gasPrice,
        uint256 baseGas,
        uint256 estimatedFees,
        bool requireValidRequest
    ) internal virtual {
        {
            (
                bool isTrustedForwarder,
                bool active,
                bool signerMatch,
                address signer
            ) = _validate(request);

            if (requireValidRequest) {
                if (!isTrustedForwarder) {
                    revert("Fusion: Untrusted forwarder");
                }

                if (!active) {
                    revert("Fusion: Expired request");
                }

                if (!signerMatch) {
                    revert("Fusion: Invalid signer");
                }
            }

            if (!isTrustedForwarder || !active || !signerMatch) {
                revert("Fusion: Execution failed");
            }

            _useNonce(signer);
        }

        // Encode the parameters for optimized gas usage
        bytes memory encodedParams = encodeExecuteParams(
            request,
            token,
            gasPrice,
            baseGas,
            estimatedFees
        );

        (bool success, ) = request.recipient.call{gas: request.gas}(
            encodedParams
        );

        Forwarder._checkForwardedGas(gasleft(), request.gas);

        if (!success) {
            revert("Fusion: Execution failed");
        }
    }

    /**
     * @notice Executes a batch of transactions using the provided data
     * @param request The ExecuteBatch request
     * @param token The token address
     * @param gasPrice The gas price
     * @param baseGas The base gas
     * @param estimatedFees The estimated fees
     * @param requireValidRequest If the request should be validated
     */
    function _executeBatch(
        Forwarder.ForwardExecuteBatchData calldata request,
        address token,
        uint256 gasPrice,
        uint256 baseGas,
        uint256 estimatedFees,
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
                revert("Fusion: Untrusted forwarder");
            }

            if (!active) {
                revert("Fusion: Expired request");
            }

            if (!signerMatch) {
                revert("Fusion: Invalid signer");
            }
        }

        if (!isTrustedForwarder || !active || !signerMatch) {
            revert("Fusion: Execution failed");
        }

        _useNonce(signer);

        bytes memory encodedParams = encodeExecuteBatchParams(
            request,
            token,
            gasPrice,
            baseGas,
            estimatedFees
        );

        (bool success, ) = request.recipient.call{gas: request.gas}(
            encodedParams
        );

        Forwarder._checkForwardedGas(gasleft(), request.gas);

        if (!success) {
            revert("Fusion: Execution failed");
        }
    }

    /**
     * @notice Encodes the parameters for the execute function
     * @param request The forwarder request
     * @param token The token address
     * @param gasPrice The gas price
     * @param baseGas The base gas
     * @param estimatedFees The estimated fees
     * @return encodedParams The encoded parameters
     */
    function encodeExecuteParams(
        Forwarder.ForwardExecuteData calldata request,
        address token,
        uint256 gasPrice,
        uint256 baseGas,
        uint256 estimatedFees
    ) internal pure returns (bytes memory) {
        bytes4 functionSignature = IFusion.executeTxWithForwarder.selector;
        return
            abi.encodeWithSelector(
                functionSignature,
                request.proof,
                request.txData,
                token,
                gasPrice,
                baseGas,
                estimatedFees
            );
    }

    /**
     * @notice Validates the forwarder request
     * @param request The forwarder request
     * @return isTrustedForwarder If the forwarder is trusted
     * @return active If the request is active
     * @return signerMatch If the signer matches
     * @return signer The signer address
     */
    function _validate(
        Forwarder.ForwardExecuteData calldata request
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
     * @param request The forwarder request
     * @return isValid If the signature is valid
     * @return recovered The recovered signer
     */
    function _recoverForwardSigner(
        Forwarder.ForwardExecuteData calldata request
    ) internal view virtual returns (bool, address) {
        (address recovered, ECDSA.RecoverError err, ) = _hashTypedDataV4(
            Forwarder.hashForwardExecute(request)
        ).tryRecover(request.signature);

        return (err == ECDSA.RecoverError.NoError, recovered);
    }

    /**
     * @notice Encodes the parameters for the executeBatch function
     * @param request The forwarder request
     * @param token The token address
     * @param gasPrice The gas price
     * @param baseGas The base gas
     * @param estimatedFees The estimated fees
     * @return encodedParams The encoded parameters
     */
    function encodeExecuteBatchParams(
        Forwarder.ForwardExecuteBatchData calldata request,
        address token,
        uint256 gasPrice,
        uint256 baseGas,
        uint256 estimatedFees
    ) internal virtual returns (bytes memory encodedParams) {
        bytes4 functionSelector = IFusion.executeBatchTxWithForwarder.selector;

        encodedParams = abi.encodeWithSelector(
            functionSelector,
            request.proof,
            request.txDatas,
            token,
            gasPrice,
            baseGas,
            estimatedFees
        );
    }

    /**
     * @notice Validates the forwarder request
     * @param request The forwarder request
     * @return isTrustedForwarder If the forwarder is trusted
     * @return active If the request is active
     * @return signerMatch If the signer matches
     * @return signer The signer address
     */
    function _validate(
        Forwarder.ForwardExecuteBatchData calldata request
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
     * @param request The forwarder request
     * @return isValid If the signature is valid
     * @return recovered The recovered signer
     */
    function _recoverForwardSigner(
        Forwarder.ForwardExecuteBatchData calldata request
    ) internal view virtual returns (bool, address) {
        (address recovered, ECDSA.RecoverError err, ) = _hashTypedDataV4(
            Forwarder.hashForwardExecuteBatch(request)
        ).tryRecover(request.signature);

        return (err == ECDSA.RecoverError.NoError, recovered);
    }
}
