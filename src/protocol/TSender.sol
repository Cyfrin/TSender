// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

/**
 * @title TSender
 * @author Patrick Collins
 * @author Cyfrin
 *
 * @notice Hyper gas efficient implementation of a multi-recipient airdrop
 * @notice inspired by https://github.com/PopPunkLLC/GasliteDrop
 */
contract TSender {
    /**
     *
     * @param tokenAddress
     * @param recipients
     * @param amounts
     * @param totalAmount
     */
    function airdropErc20s(
        address tokenAddress,
        address[] calldata recipients,
        uint256[] calldata amounts,
        uint256 totalAmount
    ) external payable {
        assembly {
            // check for equal lengths
            if iszero(eq(recipients.length, amounts.length)) {
                mstore(0x00, 0x50a302d6) // cast sig TSender__LengthsDontMatch()
                revert(0x1c, 0x04)
            }
        }
    }
}
