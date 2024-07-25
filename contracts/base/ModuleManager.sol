// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

import "../common/SelfAuthorized.sol";
import {Enum} from "../libraries/Enum.sol";
import "./Executor.sol";

/**
 * @title ModuleManager - Manages the modules of the Fusion Wallet.
 * @author Anoy Roy Chowdhury - <anoy@valerium.id>
 */

abstract contract ModuleManager is SelfAuthorized, Executor {
    event EnabledModule(address module);
    event DisabledModule(address module);

    // The sentinel value used to indicate the start of the list.
    address internal constant SENTINEL_MODULES = address(0x1);

    // A mapping from modules to the previous module in the list.
    mapping(address => address) internal modules;

    /**
     * @notice Initializes the linked list with the sentinel value.
     */
    constructor() {
        modules[SENTINEL_MODULES] = SENTINEL_MODULES;
    }

    /**
     * @notice Enables a module for the Fusion Wallet.
     * @param module The module to be enabled.
     */
    function enableModule(address module) external authorized {
        // Module address cannot be null or sentinel.
        if (module == address(0) || module == SENTINEL_MODULES)
            revert("Fusion: INVALID_MODULE_ADDRESS");
        // Module cannot be added twice.
        if (modules[module] != address(0)) revert("Fusion: MODULE_EXISTS");

        modules[module] = modules[SENTINEL_MODULES];
        modules[SENTINEL_MODULES] = module;
        emit EnabledModule(module);
    }

    /**
     * @notice Disables a module for the Fusion Wallet.
     * @param prevModule The previous module in the list.
     * @param module The module to be disabled.
     */
    function disableModule(
        address prevModule,
        address module
    ) external authorized {
        // Validate module address and check that it corresponds to module index.
        if (module == address(0) || module == SENTINEL_MODULES)
            revert("Fusion: INVALID_MODULE_ADDRESS");
        if (modules[prevModule] != module) revert("Fusion: INVALID_MODULE");
        modules[prevModule] = modules[module];
        modules[module] = address(0);
        emit DisabledModule(module);
    }

    function execTransactionFromModule(
        address to,
        uint256 value,
        bytes memory data,
        Enum.Operation operation
    ) external returns (bool success) {
        require(
            modules[msg.sender] != address(0),
            "Fusion: UNAUTHORIZED_MODULE"
        );
        success = execute(to, value, data, operation, gasleft());
    }

    /**
     * @notice Returns the modules of the linked list.
     * @param start The start of the linked list or the sentinel address.
     * @param pageSize The size of the page.
     */
    function getModulesPaginated(
        address start,
        uint256 pageSize
    ) external view returns (address[] memory array, address next) {
        if (start != SENTINEL_MODULES && !isModuleEnabled(start))
            revert("Fusion: INVALID_START_MODULE");
        if (pageSize == 0) revert("Fusion: INVALID_PAGE_SIZE");
        // Init array with max page size
        array = new address[](pageSize);

        // Populate return array
        uint256 moduleCount = 0;
        next = modules[start];
        while (
            next != address(0) &&
            next != SENTINEL_MODULES &&
            moduleCount < pageSize
        ) {
            array[moduleCount] = next;
            next = modules[next];
            moduleCount++;
        }

        /**
          Because of the argument validation, we can assume that the loop will always iterate over the valid module list values
          and the `next` variable will either be an enabled module or a sentinel address (signalling the end). 
          
          If we haven't reached the end inside the loop, we need to set the next pointer to the last element of the modules array
          because the `next` variable (which is a module by itself) acting as a pointer to the start of the next page is neither 
          included to the current page, nor will it be included in the next one if you pass it as a start.
        */
        if (next != SENTINEL_MODULES) {
            next = array[moduleCount - 1];
        }
        // Set correct size of returned array
        /* solhint-disable no-inline-assembly */
        /// @solidity memory-safe-assembly
        assembly {
            mstore(array, moduleCount)
        }
        /* solhint-enable no-inline-assembly */
    }

    /**
     * @notice Checks if the module is a part of the linked list.
     * @param module The module to be checked.
     */
    function isModuleEnabled(address module) public view returns (bool) {
        return SENTINEL_MODULES != module && modules[module] != address(0);
    }
}
