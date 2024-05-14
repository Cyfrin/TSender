// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Base_Test, ITSender} from "test/Base_Test.t.sol";

abstract contract Base_NoCheck is Base_Test {
    function test_airDropErc20ThrowsErrorWhenLengthsDontMatch(
        uint16, /*recipientsNumberCapped*/
        uint16, /*amountsNumberCapped*/
        address /*sender*/
    ) public pure override {
        assertEq(true, true);
    }

    function test_airDropErc20ThrowsErrorWhenTotalsDontMatch(uint128 /*amount*/ ) public pure override {
        assertEq(true, true);
    }

    function test_revertsIfValueIsSent(uint256 /*amount*/ ) public pure override {
        assertEq(true, true);
    }

    function test_isValidRecipientsReturnsFalseOnDuplicates() public pure override {
        assertEq(true, true);
    }

    function test_isValidRecipientsReturnsTrue() public pure override {
        assertEq(true, true);
    }

    function test_zeroAddressRecipientReverts(uint128, /*amount*/ address /*sender*/ ) public pure override {
        assertEq(true, true);
    }

    function test_revertsWhenNoProperFunctionSelectorUsed(bytes4 /*selector*/ ) public pure override {
        assertEq(true, true);
    }

    function test_zeroLengthRecipientsReturnsFalse() public pure override {
        assertEq(true, true);
    }
}
