// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Genesis Manager - Manages the genesis of the Inheritable contract.
 * @author Anoy Roy Chowdhury - <anoy@valerium.id>
 */

abstract contract GenesisManager {
    // The address of the account that initially created the factory contract.
    address private GenesisAddress;

    // The constructor sets the GenesisAddress.
    constructor() {
        GenesisAddress = msg.sender;
    }

    /**
     * @notice Modifier to restrict access to the Genesis Address.
     */
    modifier onlyGenesis() {
        require(
            msg.sender == GenesisAddress,
            "Only the Genesis Address can call this function"
        );
        _;
    }

    /**
     * @notice Allows the Genesis Address to transfer ownership.
     * @param newGenesis Address of the new Genesis Address.
     */
    function transferGenesis(address newGenesis) external onlyGenesis {
        GenesisAddress = newGenesis;
    }
}
