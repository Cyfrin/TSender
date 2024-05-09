// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

interface ITSender {
    function airdropERC20(
        address tokenAddress,
        address[] calldata recipients,
        uint256[] calldata amounts,
        uint256 totalAmount
    ) external;

    function airdropETH(address[] calldata recipients, uint256[] calldata amounts, uint256 totalAmount)
        external
        payable;
}
