// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Quote - Collection of structs used in Fusion gas quotes.
 * @author Anoy Roy Chowdhury - <anoy@valerium.id>
 */
library Quote {
    // GasQuote struct
    struct GasQuote {
        address token;
        uint256 gasPrice;
        uint256 baseGas;
        uint256 estimatedFees;
        address gasRecipient;
    }
}
