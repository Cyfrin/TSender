// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";
import {SymTest} from "lib/halmos-cheatcodes/src/SymTest.sol";
import {TSender} from "src/protocol/TSender.sol";
import {MockERC20} from "test/mocks/MockERC20.sol";

// I think for a lot of this, the invariants are going to run into path explosion
// Because of this, fuzzing is likely a better solution. When we run our fuzz tests,
// all the tests in this folder will get picked up too

// Invariants:
// 1. The output of the Huff code should always be exactly the same as the solidity
// 2. The Huff code should always revert if the solidity reverts

// Rules
// 3. If sum of amounts don't match, it should always revert
// 4. If the lengths don't match, it should always revert
// 5. Users should always get exactly how much they are supposed to get
// 6. Funds cannot get locked in the contract
contract FormalEquivalence is SymTest, Test {
    TSender public huffTSender;
    TSender public yulTSender;
    MockERC20 public mockERC20;

    uint256 constant ONE = 1e18;

    function setUp() public {
        // We have to deploy our huff contract a slightly different way for Halmos to work
        // Copy the text from compiled_huff.txt and put it in here
        // This does not include the contract creation code
        // huffc src/protocol/TSender.huff --bytecode > compiled_huff.txt
        bytes memory deployBytecode =
            hex"60d98060093d393df3346100d5575f3560e01c806382947abe14610015575b6084358060200260a401806080523514610036576350a302d65f526004601cfd5b6323b872dd5f5233602052306040526064356060525f5f6064601c5f6004355af16100685763fa10ea065f526004601cfd5b63a9059cbb5f525f60043560805160840360843560051b60a40160a45b82818035602052033580604052850194505f5f6044601c5f885af16100b15763fa10ea065f526004601cfd5b602001818110610085576064358514156100c757005b6363b625635f526004601cfd005b5f5ffd";
        address tSenderHuffAddr;
        assembly {
            tSenderHuffAddr := create(0, add(deployBytecode, 0x20), mload(deployBytecode))
        }

        huffTSender = TSender(tSenderHuffAddr);
        yulTSender = new TSender();
        mockERC20 = new MockERC20();
    }

    // halmos --function testEachShouldSendTheExactAmount --solver-timeout-assertion 0
    function testEachShouldSendTheExactAmount(address sender, uint128 amountCapped, address recipient) public {
        vm.assume(recipient != address(0));
        uint256 amount = uint256(amountCapped);
        uint256 totalAmount = amount * 2;

        vm.startPrank(sender);
        mockERC20.mint(totalAmount);
        mockERC20.approve(address(huffTSender), totalAmount);
        mockERC20.approve(address(yulTSender), totalAmount);
        vm.stopPrank();

        address[] memory recipients = new address[](1);
        recipients[0] = recipient;
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = uint256(amount);

        vm.startPrank(sender);
        yulTSender.airdropERC20(address(mockERC20), recipients, amounts, uint256(amount));
        huffTSender.airdropERC20(address(mockERC20), recipients, amounts, uint256(amount));
        vm.stopPrank();

        // User should have received the correct amount
        assert(mockERC20.balanceOf(recipient) == totalAmount);
    }

    // halmos --function testBothRevertIfValueIsSent --solver-timeout-assertion 0
    function testBothRevertIfValueIsSent(uint128 amountCapped, address recipient) public {
        uint256 amount = uint256(amountCapped);

        // Arrange
        vm.startPrank(address(this));
        mockERC20.mint(amount);
        mockERC20.approve(address(yulTSender), amount);
        mockERC20.approve(address(huffTSender), amount);
        vm.stopPrank();

        address[] memory recipients = new address[](1);
        recipients[0] = recipient;
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = amount;

        bytes4 selector = TSender.airdropERC20.selector;
        bytes memory data = abi.encodeWithSelector(selector, address(mockERC20), recipients, amounts, amount);

        // Act
        vm.deal(address(this), amount * 2);
        (bool succYul,) = address(yulTSender).call{value: amount}(data);
        (bool succHuff,) = address(huffTSender).call{value: amount}(data);
        assert(succYul == succHuff);
    }

    // // halmos --function testBothRevertWhenLengthsDontMatch --solver-timeout-assertion 0
    // Removed this test, halmos has a hard time with for loops needed to populate the arrays
    // function testBothRevertWhenLengthsDontMatch(uint8 recipientsNumberCapped, uint8 amountsNumberCapped, address sender)
    //     public
    //     virtual;

    // halmos --function testMultiSendResultsInSameSuccess --solver-timeout-assertion 0
    function testMultiSendResultsInSameSuccess(uint128 totalAmountCapped, address sender, uint256 modSeed) public {
        vm.assume(sender != address(0));
        vm.assume(modSeed != 0);
        uint256 totalAmount = uint256(totalAmountCapped);
        uint256 numberOfRecipients = 4;

        // Arrange
        vm.startPrank(sender);
        mockERC20.mint(totalAmount * 2);
        mockERC20.approve(address(yulTSender), totalAmount);
        mockERC20.approve(address(huffTSender), totalAmount);
        vm.stopPrank();

        address[] memory recipients = new address[](numberOfRecipients);
        recipients[0] = address(uint160(numberOfRecipients + 1));
        recipients[1] = address(uint160(numberOfRecipients + 2));
        recipients[2] = address(uint160(numberOfRecipients + 3));
        recipients[3] = address(uint160(numberOfRecipients + 4));

        uint256 amountLeft = totalAmount;
        uint256[] memory amounts = new uint256[](numberOfRecipients);
        amounts[0] = amountLeft % modSeed;
        amountLeft -= amounts[0];
        amounts[1] = amountLeft % modSeed;
        amountLeft -= amounts[1];
        amounts[2] = amountLeft % modSeed;
        amountLeft -= amounts[2];
        amounts[3] = amountLeft;

        bytes4 selector = TSender.airdropERC20.selector;
        bytes memory data = abi.encodeWithSelector(selector, address(mockERC20), recipients, amounts, totalAmount);

        // Act
        vm.startPrank(sender);
        (bool succYul,) = address(yulTSender).call(data);
        (bool succHuff,) = address(huffTSender).call(data);
        vm.stopPrank();

        // Assert
        assert(succYul == succHuff);
        assert(mockERC20.balanceOf(recipients[0]) == amounts[0] * 2);
        assert(mockERC20.balanceOf(recipients[1]) == amounts[1] * 2);
        assert(mockERC20.balanceOf(recipients[2]) == amounts[2] * 2);
        assert(mockERC20.balanceOf(recipients[3]) == amounts[3] * 2);
    }
}
