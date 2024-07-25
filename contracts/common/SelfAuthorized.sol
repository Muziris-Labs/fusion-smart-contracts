// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

/**
 * @title SelfAuthorized - Authorizes current contract to perform actions to itself.
 * @author Anoy Roy Chowdhury - <anoy@valerium.id>
 */
abstract contract SelfAuthorized {
    function requireSelfCall() private view {
        if (msg.sender != address(this)) {
            revert("ONLY_CALLABLE_BY_SELF");
        }
    }

    modifier authorized() {
        // Modifiers are copied around during compilation. This is a function call as it minimized the bytecode size
        requireSelfCall();
        _;
    }
}
