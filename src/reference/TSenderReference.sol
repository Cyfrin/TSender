// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ITSender} from "src/interfaces/ITSender.sol";

/*
 * @title TSenderReference
 * @author Patrick Collins 
 * @author Cyfrin
 * 
 * @notice This contract is meant to be the less gas efficient version of TSender
 */
contract TSenderReference is ITSender {
    error TSender__TotalDoesntAddUp();
    error TSender__LengthsDontMatch();
    error TSender__TransferFailed();
    error TSender__ZeroAddress();

    /**
     * @notice This function is meant to be used to airdrop ERC20 tokens to a list of users
     * @param tokenAddress The address of the ERC20 token to be airdropped
     * @param recipients The addresses of the users to receive the airdrop
     * @param amounts The amounts of tokens to be airdropped to each user
     * @param totalAmount The total amount of tokens to be airdropped
     */
    function airdropERC20(
        address tokenAddress,
        address[] calldata recipients,
        uint256[] calldata amounts,
        uint256 totalAmount
    ) external {
        if (recipients.length != amounts.length) {
            revert TSender__LengthsDontMatch();
        }
        uint256 actualTotal;
        bool success = IERC20(tokenAddress).transferFrom(msg.sender, address(this), totalAmount);
        if (!success) {
            revert TSender__TransferFailed();
        }
        for (uint256 i; i < recipients.length; i++) {
            actualTotal += amounts[i];
            if (recipients[i] == address(0)) {
                revert TSender__ZeroAddress();
            }
            IERC20(tokenAddress).transfer(recipients[i], amounts[i]);
        }
        if (actualTotal != totalAmount) {
            revert TSender__TotalDoesntAddUp();
        }
    }

    /**
     * @notice This function is meant to be used to check if the contract is a valid TSender contract
     * @notice It will check for:
     *  - Duplicate addresses
     *  - Zero address sends
     *  - There is at least 1 recipient
     *  - All amounts are > 0
     *  - Lengths of arrays match
     * @param recipients The list of addresses to check
     * @param amounts The list of amounts to check
     * @return bool
     */
    function areListsValid(address[] calldata recipients, uint256[] calldata amounts) external pure returns (bool) {
        if (recipients.length == 0) {
            return false;
        }
        if (recipients.length != amounts.length) {
            return false;
        }
        for (uint256 i; i < recipients.length; i++) {
            if (recipients[i] == address(0)) {
                return false;
            }
            if (amounts[i] == 0) {
                return false;
            }
            for (uint256 j = i + 1; j < recipients.length; j++) {
                if (recipients[i] == recipients[j]) {
                    return false;
                }
            }
        }
        return true;
    }
}
