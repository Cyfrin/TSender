// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Base_Test, ITSender} from "test/Base_Test.t.sol";
import {TSender} from "src/protocol/TSender.sol";
import {MockERC20} from "test/mocks/MockERC20.sol";
import {HuffDeployer} from "lib/foundry-huff/src/HuffDeployer.sol";

contract TSenderHuffNoCheckTest is Base_Test {
    string public constant tsenderHuffLocation = "protocol/TSender_NoCheck";

    function setUp() public override {
        TSender tSenderHuff = TSender(HuffDeployer.config().deploy(tsenderHuffLocation));
        tSender = ITSender(address(tSenderHuff));
        mockERC20 = new MockERC20();
    }

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
}
