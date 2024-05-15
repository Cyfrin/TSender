// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Base_Test, ITSender} from "test/Base_Test.t.sol";
import {TSender} from "src/protocol/TSender.sol";
import {MockERC20} from "test/mocks/MockERC20.sol";

contract TSenderYulTest is Base_Test {
    function setUp() public {
        TSender tSenderYul = new TSender();
        tSender = ITSender(address(tSenderYul));
        mockERC20 = new MockERC20();
        _hasSafetyChecks = true;
    }
}
