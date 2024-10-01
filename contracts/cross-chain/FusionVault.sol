// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

import "./TeamManager.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../common/GenesisManager.sol";

/**
 * @title Fusion Vault - This contract is used to manage the vault for the Fusion wallet.
 * @dev This contract is a base contract for managing the vault for the Fusion Wallet.
 * @author Anoy Roy Chowdhury - <anoy@valerium.id>
 */

contract FusionVault is TeamManager, GenesisManager {
    event DepositReceived(
        address indexed token,
        address indexed sender,
        uint256 amount
    );
    event GenesisWithdrawal(address indexed token, uint256 amount);
    event MemberWithdrawal(
        address indexed token,
        address indexed member,
        uint256 amount
    );
    event WithdrawAllGenesis(address indexed token);

    // The maximum withdrawal amount allowed in the vault by members.
    uint256 private maxWithdrawAmount = 0;

    // The snapshot time of the wallet.
    uint256 public snapshotTime;

    /**
     * @notice Initializes the contract with the address of the genesis account and maxDeposit.
     */
    constructor(uint256 _maxWithdrawAmount) {
        maxWithdrawAmount = _maxWithdrawAmount;
        snapshotTime = block.timestamp;
    }

    /**
     * @notice Deposits the token into the vault.
     * @param token The address of the token to be deposited.
     * @param _amount The amount to be deposited.
     */
    function deposit(address token, uint256 _amount) external payable {
        if (token == address(0)) {
            require(msg.value == _amount, "Invalid amount");
        } else {
            require(
                IERC20(token).transferFrom(msg.sender, address(this), _amount),
                "Transfer failed"
            );
        }

        emit DepositReceived(token, msg.sender, _amount);
    }

    /**
     * @notice Withdraws the token from the vault to the genesis address.
     * @param token The address of the token to be withdrawn.
     * @param _amount The amount to be withdrawn.
     */
    function withdraw(address token, uint256 _amount) external onlyGenesis {
        if (token == address(0)) {
            payable(msg.sender).transfer(_amount);
        } else {
            require(
                IERC20(token).transfer(msg.sender, _amount),
                "Transfer failed"
            );
        }
        emit GenesisWithdrawal(token, _amount);
    }

    /**
     * @notice Withdraws all the tokens from the vault to the genesis address.
     * @param token The address of the token to be withdrawn.
     */
    function withdrawAll(address token) external onlyGenesis {
        if (token == address(0)) {
            payable(msg.sender).transfer(address(this).balance);
        } else {
            IERC20(token).transfer(
                msg.sender,
                IERC20(token).balanceOf(address(this))
            );
        }
        emit WithdrawAllGenesis(token);
    }

    /**
     * @notice Adds a team member to the vault.
     * @param member The address of the member to be added.
     */
    function addTeamMember(address member) external onlyGenesis {
        addMember(member);
    }

    /**
     * @notice Removes a team member from the vault.
     * @param prevMember The address of the previous member.
     * @param member The address of the member to be removed.
     */
    function removeTeamMember(
        address prevMember,
        address member
    ) external onlyGenesis {
        removeMember(prevMember, member);
    }

    /**
     * @notice Withdraws the token from the vault to the member address.
     * @param token The address of the token to be withdrawn.
     * @param _amount The amount to be withdrawn.
     */
    function memberWithdrawal(address token, uint256 _amount) external {
        require(isMember(msg.sender), "Unauthorized access");

        require(_amount <= maxWithdrawAmount, "Invalid amount");

        if (token == address(0)) {
            require(_amount <= address(this).balance, "Insufficient balance");
            payable(msg.sender).transfer(_amount);
        } else {
            IERC20(token).transfer(msg.sender, _amount);
        }

        emit MemberWithdrawal(token, msg.sender, _amount);
    }

    /**
     * @notice Updates the snapshot time of the vault.
     */
    function updateSnapshotTime() external onlyGenesis {
        snapshotTime = block.timestamp;
    }

    /**
     * @notice Changes the maximum withdrawal amount allowed in the vault by members.
     * @param _maxWithdrawAmount The new maximum withdrawal amount.
     */
    function changeMaxWithdrawAmount(
        uint256 _maxWithdrawAmount
    ) external onlyGenesis {
        maxWithdrawAmount = _maxWithdrawAmount;
    }
}
