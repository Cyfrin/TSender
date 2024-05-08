// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

interface ITSender {
    function airdropErc20s(
        address tokenAddress,
        address[] calldata recipients,
        uint256[] calldata amounts,
        uint256 totalAmount
    ) external;

    function airDropEth(address[] calldata recipients, uint256[] calldata amounts, uint256 totalAmount)
        external
        payable;
}
