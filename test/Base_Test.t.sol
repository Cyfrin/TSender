// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";
import {TSenderReference} from "src/reference/TSenderReference.sol";
import {ITSender} from "src/interfaces/ITSender.sol";
import {MockERC20} from "test/mocks/MockERC20.sol";
import {MockFalseTransferFromERC20} from "test/mocks/MockFalseTransferFromERC20.sol";

contract Base_Test is Test {
    ITSender public tSender;
    MockERC20 public mockERC20;
    uint256 public constant ONE = 1e18;
    address public recipientOne = makeAddr("recipientOne");
    address public recipientTwo = makeAddr("recipientTwo");

    function setUp() public virtual {
        TSenderReference senderReference = new TSenderReference();
        tSender = ITSender(address(senderReference));
        mockERC20 = new MockERC20();
    }

    function testAirdropERC20ToSingleUnit() public {
        uint256 amount = ONE;
        address sender = address(77); // 0x000000000000000000000000000000000000004D
        address knownRecipient = address(44); // 0x2c

        vm.startPrank(sender);
        mockERC20.mint(uint256(amount));
        mockERC20.approve(address(tSender), uint256(amount));
        vm.stopPrank();

        address[] memory recipients = new address[](1);
        recipients[0] = knownRecipient;
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = uint256(amount);

        // Act
        vm.prank(sender);
        tSender.airdropERC20(address(mockERC20), recipients, amounts, uint256(amount));

        // Assert
        assertEq(mockERC20.balanceOf(knownRecipient), uint256(amount));
    }

    function test_airDropErc20ToSingleFuzz(uint128 amount, address sender) public {
        vm.assume(sender != address(0) && sender != address(this) && sender != address(tSender));

        // Arrange
        vm.startPrank(sender);
        mockERC20.mint(uint256(amount));
        mockERC20.approve(address(tSender), uint256(amount));
        vm.stopPrank();

        address[] memory recipients = new address[](1);
        recipients[0] = recipientOne;
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = uint256(amount);

        // Act
        vm.prank(sender);
        tSender.airdropERC20(address(mockERC20), recipients, amounts, uint256(amount));

        // Assert
        assertEq(mockERC20.balanceOf(recipientOne), uint256(amount));
    }

    // We set amount to a uint128 to not run into overflows
    function test_airDropErc20ToMany(uint128 amount, address sender) public {
        vm.assume(sender != address(0) && sender != address(this) && sender != address(tSender));

        // Arrange
        uint256 uint256Amount = uint256(amount);
        uint256 expectedTotalAmount = (uint256Amount * 2) + ONE;

        vm.startPrank(sender);
        mockERC20.mint(expectedTotalAmount);
        mockERC20.approve(address(tSender), expectedTotalAmount);
        vm.stopPrank();

        address[] memory recipients = new address[](2);
        recipients[0] = recipientOne;
        recipients[1] = recipientTwo;
        uint256[] memory amounts = new uint256[](2);
        amounts[0] = uint256Amount;
        amounts[1] = uint256Amount + ONE;

        // Act
        vm.prank(sender);
        tSender.airdropERC20(address(mockERC20), recipients, amounts, expectedTotalAmount);

        // Assert
        assertEq(mockERC20.balanceOf(recipientOne), uint256Amount);
        assertEq(mockERC20.balanceOf(recipientTwo), uint256Amount + ONE);
    }

    function test_airDropErc20ThrowsErrorWhenLengthsDontMatch() public {
        // Arrange
        address[] memory recipients = new address[](1);
        recipients[0] = recipientOne;
        uint256[] memory amounts = new uint256[](2);
        amounts[0] = uint256(ONE);
        amounts[1] = uint256(ONE);

        // Act
        vm.expectRevert(TSenderReference.TSender__LengthsDontMatch.selector);
        tSender.airdropERC20(address(mockERC20), recipients, amounts, uint256(ONE));
    }

    function test_airDropErc20ThrowsErrorWhenTotalsDontMatch(uint128 amount) public {
        // Arrange
        uint256 uint256Amount = uint256(amount);
        uint256 expectedTotalAmount = (uint256Amount * 2) + ONE;

        vm.startPrank(address(this));
        mockERC20.mint(expectedTotalAmount);
        mockERC20.approve(address(tSender), expectedTotalAmount);
        vm.stopPrank();

        address[] memory recipients = new address[](2);
        recipients[0] = recipientOne;
        recipients[1] = recipientTwo;
        uint256[] memory amounts = new uint256[](2);
        amounts[0] = uint256Amount;
        amounts[1] = uint256Amount;

        // Act
        vm.expectRevert(TSenderReference.TSender__TotalDoesntAddUp.selector);
        tSender.airdropERC20(address(mockERC20), recipients, amounts, expectedTotalAmount);
    }
}
