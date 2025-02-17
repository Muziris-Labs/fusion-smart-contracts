// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

/**
 * @dev FusionContext - A contract that charges fees for the transaction.
 * @author Anoy Roy Chowdhury - <anoy@valerium.id>
 */

abstract contract FusionContext {
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
            uint256 transferAmount = gasFee / 10 ** (18 - decimals);

            // Low-level call with additional check for tokens without return value
            (bool success, bytes memory data) = token.call(
                abi.encodeWithSelector(
                    IERC20.transfer.selector,
                    GasTank,
                    transferAmount
                )
            );

            bool transferSucceeded = success &&
                (data.length == 0 || abi.decode(data, (bool)));

            if (!transferSucceeded) {
                revert("Fusion: fee transfer failed");
            }
        } else {
            (bool success, ) = GasTank.call{value: gasFee}("");
            if (!success) {
                revert("Fusion: fee transfer failed");
            }
        }
    }
}
