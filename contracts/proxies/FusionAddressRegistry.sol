// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

/**
 * @title FusionAddressRegistry - Manages the address registry of the Fusion Wallet.
 * @author Anoy Roy Chowdhury - <anoy@valerium.id>
 */

contract FusionAddressRegistry {
    event UpdatedRegistry(
        Selector indexed selector,
        address indexed newAddress
    );
    event InitializedRegistry(
        address TxVerifier,
        address FusionForwarder,
        address GasTank
    );

    // Enum of all the modules in the Fusion Wallet.
    enum Selector {
        TxVerifier,
        FusionForwarder,
        GasTank
    }

    // The Address of Verifier contract used for proof verification.
    address public TxVerifier;

    // The Address of the Fusion Forwarder contract.
    address public FusionForwarder;

    // The Address of the Gas Tank.
    address public GasTank;

    /**
     * @notice Setup function sets the initial storage of the contract.
     * @param TxVerifier_  The address of the TxVerifier contract.
     * @param FusionForwarder_ The address of the FusionForwarder contract.
     * @param GasTank_  The address of the GasTank.
     */
    function _setupRegistry(
        address TxVerifier_,
        address FusionForwarder_,
        address GasTank_
    ) internal {
        require(TxVerifier == address(0), "Registry already initialized");
        require(FusionForwarder == address(0), "Registry already initialized");
        require(GasTank == address(0), "Registry already initialized");

        TxVerifier = TxVerifier_;
        FusionForwarder = FusionForwarder_;
        GasTank = GasTank_;

        emit InitializedRegistry(TxVerifier_, FusionForwarder_, GasTank_);
    }

    /**
     * @notice Update the address of a module in the Fusion Wallet.
     * @param selector The module to be updated.
     * @param newAddress The new address of the module.
     */
    function _updateRegistry(Selector selector, address newAddress) internal {
        require(newAddress != address(0), "Invalid Address");

        if (selector == Selector.TxVerifier) {
            TxVerifier = newAddress;
        } else if (selector == Selector.FusionForwarder) {
            FusionForwarder = newAddress;
        } else if (selector == Selector.GasTank) {
            GasTank = newAddress;
        } else {
            revert("Invalid Selector");
        }

        emit UpdatedRegistry(selector, newAddress);
    }
}
