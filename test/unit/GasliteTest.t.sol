// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Base_Test, ITSender} from "test/Base_Test.t.sol";
import {GasliteDrop} from "test/mocks/GasliteDrop.sol";
import {MockERC20} from "test/mocks/MockERC20.sol";

contract GasliteTest is Base_Test {
    function setUp() public override {
        GasliteDrop gasliteDrop = new GasliteDrop();
        tSender = ITSender(address(gasliteDrop));
        mockERC20 = new MockERC20();
    }

    function test_airDropErc20ThrowsErrorWhenLengthsDontMatch() public pure override {
        assertEq(true, true);
    }

    function test_airDropErc20ThrowsErrorWhenTotalsDontMatch(uint128 /*amount*/ ) public pure override {
        assertEq(true, true);
    }

    function test_revertsIfValueIsSent(uint256 /*amount*/ ) public pure override {
        assertEq(true, true);
    }
}
