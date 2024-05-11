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

    /* 
     * @param tokenAddress The address of the ERC20 token to be airdropped
     * @param users The addresses of the users to receive the airdrop
     * @param amounts The amounts of tokens to be airdropped to each user
     * @param totalAmount The total amount of tokens to be airdropped
     * 
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
            IERC20(tokenAddress).transfer(recipients[i], amounts[i]);
        }
        if (actualTotal != totalAmount) {
            revert TSender__TotalDoesntAddUp();
        }
    }

    // /*
    //  * @param recipients The addresses of the users to receive the airdrop
    //  * @param amounts The amounts of ETH to be airdropped to each user
    //  * @param totalAmount The total amount of ETH to be airdropped
    //  *
    //  */
    // function airdropETH(address[] calldata recipients, uint256[] calldata amounts, uint256 totalAmount)
    //     external
    //     payable
    // {
    //     if (recipients.length != amounts.length) {
    //         revert TSender__LengthsDontMatch();
    //     }
    //     uint256 actualTotal;
    //     for (uint256 i; i < recipients.length; i++) {
    //         actualTotal += amounts[i];
    //         (bool succ,) = payable(recipients[i]).call{value: amounts[i]}("");
    //         if (!succ) {
    //             revert TSender__TransferFailed();
    //         }
    //     }
    //     if (actualTotal != totalAmount) {
    //         revert TSender__TotalDoesntAddUp();
    //     }
    // }
}
