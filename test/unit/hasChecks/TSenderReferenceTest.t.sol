// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Base_Test, ITSender} from "test/Base_Test.t.sol";
import {TSenderReference} from "src/reference/TSenderReference.sol";
import {MockERC20} from "test/mocks/MockERC20.sol";

contract TSenderReferenceTest is Base_Test {
    function setUp() public {
        TSenderReference tSenderReference = new TSenderReference();
        tSender = ITSender(address(tSenderReference));
        mockERC20 = new MockERC20();
        _hasSafetyChecks = true;
    }
}
