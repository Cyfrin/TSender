// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

/**
 * @title TSender
 * @author Patrick Collins
 * @author Cyfrin
 *
 * Original Work by:
 * @author Harrison (@PopPunkOnChain)
 * @author Gaslite (@GasliteGG)
 * @author Pop Punk LLC (@PopPunkLLC)
 * @notice https://github.com/PopPunkLLC/GasliteDrop
 */
contract TSender {
    /**
     * @param tokenAddress - the address of the ERC20 token to airdrop
     * @param recipients - the addresses to airdrop to
     * @param amounts - the amounts to airdrop to each address
     * @param totalAmount - the total amount to airdrop
     */
    function airdropERC20(
        address tokenAddress,
        address[] calldata recipients,
        uint256[] calldata amounts,
        uint256 totalAmount
    ) external {
        assembly {
            // check for equal lengths
            if iszero(eq(recipients.length, amounts.length)) {
                mstore(0x00, 0x50a302d6) // cast sig TSender__LengthsDontMatch()
                revert(0x1c, 0x04)
            }

            // transferFrom(address from, address to, uint256 amount)
            // cast sig "transferFrom(address,address,uint256)"
            mstore(0x00, hex"23b872dd")
            // from address
            mstore(0x04, caller())
            // to address (this contract)
            mstore(0x24, address())
            // total amount
            mstore(0x44, totalAmount)

            if iszero(call(gas(), tokenAddress, 0, 0x00, 0x64, 0, 0)) {
                mstore(0x00, 0xfa10ea06) // cast sig "TSender__TransferFailed()"
                revert(0x1c, 0x04)
            }

            // transfer(address to, uint256 value)
            mstore(0x00, hex"a9059cbb")
            // end of array
            let end := add(recipients.offset, shl(5, recipients.length))
            let diff := sub(recipients.offset, amounts.offset)

            // Checking totals at the end
            let addedAmount := 0
            for { let addressOffset := recipients.offset } 1 {} {
                // to address
                mstore(0x04, calldataload(addressOffset))
                // amount
                mstore(0x24, calldataload(sub(addressOffset, diff)))

                addedAmount := add(addedAmount, mload(0x24))

                // transfer the tokens
                // q why did vectorized do 0x68 instead of what we are doing 0x44?
                if iszero(call(gas(), tokenAddress, 0, 0x00, 0x44, 0, 0)) {
                    mstore(0x00, 0xfa10ea06) // cast sig "TSender__TransferFailed()"
                    revert(0x1c, 0x04)
                }

                // increment the address offset
                addressOffset := add(addressOffset, 0x20)
                // if addressOffset >= end, break
                if iszero(lt(addressOffset, end)) { break }
            }

            // Check if the totals match
            if iszero(eq(addedAmount, totalAmount)) {
                mstore(0x00, 0x63b62563) // cast sig TSender__TotalDoesntAddUp()
                revert(0x1c, 0x04)
            }
        }
    }
}
