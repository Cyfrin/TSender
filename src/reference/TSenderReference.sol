// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/*
 * @title TSenderReference
 * @author Patrick Collins 
 * @author Cyfrin
 * 
 * @notice This contract is meant to be the less gas efficient version of TSender
 */
contract TSenderReference {
    using SafeERC20 for IERC20;

    error TSenderReference__TotalDoesntAddUp();
    error TSenderReference__LengthsDontMatch();

    /* 
     * @param tokenAddress The address of the ERC20 token to be airdropped
     * @param users The addresses of the users to receive the airdrop
     * @param amounts The amounts of tokens to be airdropped to each user
     * @param totalAmount The total amount of tokens to be airdropped
     * 
     */
    function airdropErc20s(
        address tokenAddress,
        address[] calldata recipients,
        uint256[] calldata amounts,
        uint256 totalAmount
    ) external {
        if (recipients.length != amounts.length) {
            revert TSenderReference__LengthsDontMatch();
        }
        uint256 actualTotal;
        for (uint256 i; i < recipients.length; i++) {
            actualTotal += amounts[i];
            IERC20(tokenAddress).safeTransferFrom(msg.sender, recipients[i], amounts[i]);
        }
        if (actualTotal != totalAmount) {
            revert TSenderReference__TotalDoesntAddUp();
        }
    }

    /* 
     * @param recipients The addresses of the users to receive the airdrop
     * @param amounts The amounts of ETH to be airdropped to each user
     * @param totalAmount The total amount of ETH to be airdropped
     * 
     */
    function airDropEth(address[] calldata recipients, uint256[] calldata amounts, uint256 totalAmount)
        external
        payable
    {
        if (recipients.length != amounts.length) {
            revert TSenderReference__LengthsDontMatch();
        }
        uint256 actualTotal;
        for (uint256 i; i < recipients.length; i++) {
            actualTotal += amounts[i];
            (bool succ,) = payable(recipients[i]).call{value: amounts[i]}("");
            if (!succ) {
                revert();
            }
        }
        if (actualTotal != totalAmount) {
            revert TSenderReference__TotalDoesntAddUp();
        }
    }
}
