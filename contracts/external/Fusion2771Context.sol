// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

import {Context} from "./Context.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

/**
 * @dev Context variant with ERC-2771 support. This version of the context is used to support the Valerium Wallet.
 * @author Anoy Roy Chowdhury - <anoy@valerium.id>
 *
 * WARNING: Avoid using this pattern in contracts that rely in a specific calldata length as they'll
 * be affected by any forwarder whose `msg.data` is suffixed with the `from` address according to the ERC-2771
 * specification adding the address size in bytes (20) to the calldata size. An example of an unexpected
 * behavior could be an unintended fallback (or another function) invocation while trying to invoke the `receive`
 * function only accessible if `msg.data.length == 0`.
 *
 * WARNING: The usage of `delegatecall` in this contract is dangerous and may result in context corruption.
 * Any forwarded request to this contract triggering a `delegatecall` to itself will result in an invalid {_msgSender}
 * recovery.
 */

abstract contract Fusion2771Context is Context {
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    address private _trustedForwarder;

    /**
     * @notice Sets the trusted forwarder for the context, could be called only once.
     * @param forwarder The forwarder to be trusted
     */
    function setupTrustedForwarder(address forwarder) internal {
        require(
            _trustedForwarder == address(0),
            "Fusion: forwarder already set"
        );
        require(forwarder != address(0), "Fusion: invalid trusted forwarder");
        _trustedForwarder = forwarder;
    }

    /**
     * @notice Charges the fees for the transaction.
     * @param startGas Gas used before calling the function
     * @param gasPrice gas price of the transaction
     * @param baseGas base gas deducted by the relayer
     * @param GasTank address of the GasTank
     * @param token address of the token
     */
    function chargeFees(
        uint256 startGas,
        uint256 gasPrice,
        uint256 baseGas,
        address GasTank,
        address token
    ) internal {
        uint256 gasUsed = startGas - gasleft();
        uint256 gasFee = (gasUsed + baseGas) * gasPrice;

        if (token != address(0)) {
            uint8 decimals = IERC20Metadata(token).decimals();

            bool success = IERC20(token).transfer(
                GasTank,
                gasFee / 10 ** (18 - decimals)
            );

            if (!success) {
                revert("Fusion: fee transfer failed");
            }
        } else {
            (bool success, ) = GasTank.call{value: gasFee}("");
            if (!success) {
                revert("Fusion: fee transfer failed");
            }
        }
    }

    /**
     * @dev Returns the address of the trusted forwarder.
     */
    function trustedForwarder() public view virtual returns (address) {
        return _trustedForwarder;
    }

    /**
     * @dev Indicates whether any particular address is the trusted forwarder.
     */
    function isTrustedForwarder(
        address forwarder
    ) public view virtual returns (bool) {
        return forwarder == trustedForwarder();
    }

    /**
     * @dev Modifier to check if the caller is the trusted forwarder.
     */
    modifier onlyTrustedForwarder() {
        require(
            isTrustedForwarder(msg.sender),
            "Fusion: caller is not the trusted forwarder"
        );
        _;
    }

    /**
     * @dev Modifier to check if the caller is not the trusted forwarder.
     */
    modifier notTrustedForwarder() {
        require(
            !isTrustedForwarder(msg.sender),
            "Fusion: caller is the trusted forwarder"
        );
        _;
    }
}
