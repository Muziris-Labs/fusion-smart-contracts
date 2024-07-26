// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import "@openzeppelin/contracts/utils/Nonces.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "../external/Fusion2771Context.sol";
import "../libraries/Forwarder.sol";
import "../interfaces/IFusion.sol";

abstract contract ExecuteHandler is EIP712, Nonces {
    using ECDSA for bytes32;

    // Initializing the EIP712 Domain Separator
    constructor(
        string memory name,
        string memory version
    ) EIP712(name, version) {}

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

    function _recoverForwardSigner(
        Forwarder.ForwardExecuteData calldata request
    ) internal view virtual returns (bool, address) {
        (address recovered, ECDSA.RecoverError err, ) = _hashTypedDataV4(
            Forwarder.hashForwardExecute(request)
        ).tryRecover(request.signature);

        return (err == ECDSA.RecoverError.NoError, recovered);
    }

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

    function _recoverForwardSigner(
        Forwarder.ForwardExecuteBatchData calldata request
    ) internal view virtual returns (bool, address) {
        (address recovered, ECDSA.RecoverError err, ) = _hashTypedDataV4(
            Forwarder.hashForwardExecuteBatch(request)
        ).tryRecover(request.signature);

        return (err == ECDSA.RecoverError.NoError, recovered);
    }
}
