// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";
import {TSenderReference} from "src/reference/TSenderReference.sol";
import {ITSender} from "src/interfaces/ITSender.sol";
import {MockERC20} from "test/mocks/MockERC20.sol";
import {MockFalseTransferFromERC20} from "test/mocks/MockFalseTransferFromERC20.sol";
import {EnumerableSet} from "openzeppelin-contracts/contracts/utils/structs/EnumerableSet.sol";
import {console2} from "forge-std/console2.sol";

abstract contract Base_Test is Test {
    using EnumerableSet for EnumerableSet.AddressSet;

    ITSender public tSender;
    MockERC20 public mockERC20;
    uint256 public constant ONE = 1e18;
    address public recipientOne = makeAddr("recipientOne");
    address public recipientTwo = makeAddr("recipientTwo");

    EnumerableSet.AddressSet private recipientSet;

    // Does the contract check for special addresses when sending?
    // If true, run tests on that check
    // This also applies to the areListsValid function
    // If the contract has safety checks, it should also have the areListsValid function
    bool internal _hasSafetyChecks;

    /*//////////////////////////////////////////////////////////////
                              AIRDROPERC20
    //////////////////////////////////////////////////////////////*/
    // This test fuzzes the number of recipients and amounts
    // It assumes that the length is the same for both arrays
    // It also removes duplicates and special addresses from the recipients array
    function test_fuzzNumberOfRecipients(address[] calldata recipients, uint32[] memory amounts) public virtual {
        // we don't fuzz the sender so we don't get too many test rejects
        address sender = makeAddr("sender");
        // We don't vm.assume the lengths are the same, we'd get too many rejected tests
        vm.assume(recipients.length > 0);
        vm.assume(amounts.length > 0);

        // Get unique recipients
        address[] memory uniqueRecipients = _removeSpecialAddessesAndDuplicates(recipients, sender);
        // Calculate total amount using only unique recipients
        uint256 totalAmount = 0;
        uint256[] memory allAmounts = new uint256[](uniqueRecipients.length);
        for (uint256 i = 0; i < uniqueRecipients.length; i++) {
            uint256 amountToStore = amounts[i % amounts.length] == 0 ? 1 : uint256(amounts[i % amounts.length]);
            totalAmount += amountToStore;
            allAmounts[i] = amountToStore;
        }
        console2.log("Total amount", totalAmount);

        // Arrange
        vm.startPrank(sender);
        mockERC20.mint(totalAmount);
        console2.log("Sender balance", mockERC20.balanceOf(sender));
        mockERC20.approve(address(tSender), totalAmount);
        vm.stopPrank();

        // Test the areListsValid function if available
        // (only implemented in the Reference and Yul contracts)
        if (_hasSafetyChecks) {
            if (recipients.length != uniqueRecipients.length) {
                assertFalse(tSender.areListsValid(recipients, allAmounts));
            }
            assertTrue(tSender.areListsValid(uniqueRecipients, allAmounts));
        }

        // Act
        vm.prank(sender);
        uint256 startingGas = gasleft();
        tSender.airdropERC20(address(mockERC20), uniqueRecipients, allAmounts, uint256(totalAmount));
        uint256 gasUsed = startingGas - gasleft();
        console2.log("Gas used", gasUsed);

        // Assert
        assertEq(mockERC20.balanceOf(sender), 0, "Sender balance is not correct");
        for (uint256 i = 0; i < uniqueRecipients.length; i++) {
            assertEq(mockERC20.balanceOf(uniqueRecipients[i]), allAmounts[i], "Recipient balance is not correct");
        }
    }

    // Test that the contract reverts if there are zero addresses in the recipients list
    function test_zeroAddressRecipientReverts(uint128 amount, address sender) public virtual hasSafetyChecks {
        vm.assume(sender != address(0) && sender != address(this) && sender != address(tSender));

        // Arrange
        vm.startPrank(sender);
        mockERC20.mint(uint256(amount));
        mockERC20.approve(address(tSender), uint256(amount));
        vm.stopPrank();

        address[] memory recipients = new address[](1);
        recipients[0] = address(0);
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = uint256(amount);

        // Act
        vm.prank(sender);
        vm.expectRevert();
        tSender.airdropERC20(address(mockERC20), recipients, amounts, uint256(amount));
    }

    function test_airDropErc20ToSingleFuzz(uint128 amount, address sender) public virtual hasSafetyChecks {
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
        uint256 startingGas = gasleft();
        tSender.airdropERC20(address(mockERC20), recipients, amounts, uint256(amount));
        uint256 gasUsed = startingGas - gasleft();
        console2.log("Gas used", gasUsed);

        // Assert
        assertEq(mockERC20.balanceOf(recipientOne), uint256(amount));
    }

    // We set amount to a uint128 to not run into overflows
    function test_airDropErc20ToMany(uint128 amount, address sender) public virtual hasSafetyChecks {
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
        uint256 startingGas = gasleft();
        tSender.airdropERC20(address(mockERC20), recipients, amounts, expectedTotalAmount);
        uint256 gasUsed = startingGas - gasleft();
        console2.log("Gas used", gasUsed);

        // Assert
        assertEq(mockERC20.balanceOf(recipientOne), uint256Amount);
        assertEq(mockERC20.balanceOf(recipientTwo), uint256Amount + ONE);
    }

    function test_airDropErc20ThrowsErrorWhenLengthsDontMatch(
        uint16 recipientsNumberCapped,
        uint16 amountsNumberCapped,
        address sender
    ) public virtual hasSafetyChecks {
        vm.assume(recipientsNumberCapped != amountsNumberCapped);
        vm.assume(sender != address(0));

        uint256 recipientsNumber = uint256(recipientsNumberCapped);
        uint256 amountsNumber = uint256(amountsNumberCapped);

        uint256 totalAmount = ONE * amountsNumber;
        vm.startPrank(sender);
        mockERC20.mint(totalAmount);
        mockERC20.approve(address(tSender), totalAmount);
        vm.stopPrank();

        // Arrange
        address[] memory recipients = new address[](recipientsNumber);
        for (uint256 i = 0; i < recipientsNumber; i++) {
            recipients[i] = address(uint160(i + 25));
        }

        uint256[] memory amounts = new uint256[](amountsNumber);
        for (uint256 i = 0; i < amountsNumber; i++) {
            amounts[i] = ONE;
        }

        // Act
        vm.expectRevert(TSenderReference.TSender__LengthsDontMatch.selector);
        vm.prank(sender);
        tSender.airdropERC20(address(mockERC20), recipients, amounts, totalAmount);
    }

    function test_airDropErc20ThrowsErrorWhenTotalsDontMatch(uint128 amount) public virtual hasSafetyChecks {
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

    function test_revertsIfValueIsSent(uint256 amount) public virtual hasSafetyChecks {
        vm.assume(amount > 0);

        // Arrange
        vm.startPrank(address(this));
        mockERC20.mint(amount);
        mockERC20.approve(address(tSender), amount);
        vm.stopPrank();

        address[] memory recipients = new address[](1);
        recipients[0] = recipientOne;
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = amount;

        bytes4 selector = TSenderReference.airdropERC20.selector;
        bytes memory data = abi.encodeWithSelector(selector, address(mockERC20), recipients, amounts, amount);

        // Act
        vm.deal(address(this), amount);
        (bool succ,) = address(tSender).call{value: amount}(data);
        assertEq(succ, false);
    }

    function test_revertsWhenNoProperFunctionSelectorUsedWithChecks(bytes4 selector) public virtual hasSafetyChecks {
        vm.assume(selector != TSenderReference.airdropERC20.selector);
        vm.assume(selector != TSenderReference.areListsValid.selector);

        console2.logBytes4(selector);
        console2.logBytes(abi.encodeWithSelector(selector));

        (bool succ,) = address(tSender).call(abi.encodeWithSelector(selector));
        assertEq(succ, false);
    }

    function test_revertsWhenNoProperFunctionSelectorUsedNoChecks(bytes4 selector) public virtual {
        vm.assume(selector != TSenderReference.airdropERC20.selector);

        console2.logBytes4(selector);
        console2.logBytes(abi.encodeWithSelector(selector));

        (bool succ,) = address(tSender).call(abi.encodeWithSelector(selector));
        assertEq(succ, false);
    }

    function test_sendZeroAmount() public virtual hasSafetyChecks {
        // Arrange
        vm.startPrank(address(this));
        mockERC20.mint(1e9);
        mockERC20.approve(address(tSender), 1e9);
        vm.stopPrank();

        address[] memory recipients = new address[](1);
        recipients[0] = recipientOne;
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 0;

        // Act
        vm.prank(address(this));
        tSender.airdropERC20(address(mockERC20), recipients, amounts, 0);

        // Assert
        assertEq(mockERC20.balanceOf(recipientOne), 0);
    }

    /*//////////////////////////////////////////////////////////////
                         areListsValid
    //////////////////////////////////////////////////////////////*/
    // Test that the contract reverts if there are duplicates in the recipients list
    // ONLY by using the areListsValid function
    function test_areListsValidReturnsFalseOnDuplicates() public virtual hasSafetyChecks {
        address sender = makeAddr("sender");
        uint256 amount = 123;
        // Arrange
        uint256 expectedTotalAmount = amount * 2;

        vm.startPrank(sender);
        mockERC20.mint(expectedTotalAmount);
        mockERC20.approve(address(tSender), expectedTotalAmount);
        vm.stopPrank();

        address[] memory recipients = new address[](5);
        recipients[0] = sender;
        recipients[1] = address(5);
        recipients[2] = address(6);
        recipients[3] = sender;
        recipients[4] = address(7);

        uint256[] memory amounts = new uint256[](5);
        amounts[0] = amount;
        amounts[1] = amount;
        amounts[2] = amount;
        amounts[3] = amount;
        amounts[4] = amount;

        // Act
        bool isValidList = tSender.areListsValid(recipients, amounts);
        assert(!isValidList);
    }

    function test_returnsFalseIfLengthsDontMatch(address[] memory recipients, uint256[] memory amounts)
        public
        virtual
        hasSafetyChecks
    {
        vm.assume(recipients.length != amounts.length);
        bool isValidList = tSender.areListsValid(recipients, amounts);
        assert(!isValidList);
    }

    // Test that the contract reverts if there are duplicates in the recipients list
    // ONLY by using the areListsValid function
    function test_areListsValidReturnsTrue() public virtual hasSafetyChecks {
        address sender = makeAddr("sender");
        uint256 amount = 123;
        // Arrange
        uint256 expectedTotalAmount = amount * 2;

        vm.startPrank(sender);
        mockERC20.mint(expectedTotalAmount);
        mockERC20.approve(address(tSender), expectedTotalAmount);
        vm.stopPrank();

        address[] memory recipients = new address[](5);
        recipients[0] = sender;
        recipients[1] = address(10);
        recipients[2] = address(11);
        recipients[3] = address(12);
        recipients[4] = address(13);

        uint256[] memory amounts = new uint256[](5);
        amounts[0] = amount;
        amounts[1] = amount;
        amounts[2] = amount;
        amounts[3] = amount;
        amounts[4] = amount;

        // Act
        bool isValidList = tSender.areListsValid(recipients, amounts);
        assert(isValidList);
    }

    function test_zeroLengthRecipientsReturnsFalse() public virtual hasSafetyChecks {
        uint256[] memory amounts = new uint256[](0);
        address[] memory recipients = new address[](0);
        bool isValidList = tSender.areListsValid(recipients, amounts);
        assert(!isValidList);
    }

    function test_zeroAmountInAmountsReturnFalse() public virtual hasSafetyChecks {
        address sender = makeAddr("sender");
        uint256 amount = 123;
        // Arrange
        uint256 expectedTotalAmount = amount * 2;

        vm.startPrank(sender);
        mockERC20.mint(expectedTotalAmount);
        mockERC20.approve(address(tSender), expectedTotalAmount);
        vm.stopPrank();

        address[] memory recipients = new address[](5);
        recipients[0] = sender;
        recipients[1] = address(10);
        recipients[2] = address(11);
        recipients[3] = address(12);
        recipients[4] = address(13);

        uint256[] memory amounts = new uint256[](5);
        amounts[0] = amount;
        amounts[1] = amount;
        amounts[2] = amount;
        amounts[3] = 0;
        amounts[4] = amount;

        // Act
        bool isValidList = tSender.areListsValid(recipients, amounts);
        assert(!isValidList);
    }

    function test_zeroAddressReturnsFalse() public virtual hasSafetyChecks {
        address sender = makeAddr("sender");
        uint256 amount = 123;
        // Arrange
        uint256 expectedTotalAmount = amount * 2;

        vm.startPrank(sender);
        mockERC20.mint(expectedTotalAmount);
        mockERC20.approve(address(tSender), expectedTotalAmount);
        vm.stopPrank();

        address[] memory recipients = new address[](5);
        recipients[0] = sender;
        recipients[1] = address(10);
        recipients[2] = address(11);
        recipients[3] = address(0);
        recipients[4] = address(13);

        uint256[] memory amounts = new uint256[](5);
        amounts[0] = amount;
        amounts[1] = amount;
        amounts[2] = amount;
        amounts[3] = amount;
        amounts[4] = amount;

        // Act
        bool isValidList = tSender.areListsValid(recipients, amounts);
        assert(!isValidList);
    }

    /*//////////////////////////////////////////////////////////////
                               GAS TESTS
    //////////////////////////////////////////////////////////////*/
    function _gasTest(uint256 iterations) public {
        address sender = makeAddr("sender");
        uint256 numberOfRecipients = iterations;

        // Arrange
        uint256 uint256Amount = ONE;
        uint256 expectedTotalAmount = ONE * numberOfRecipients;

        vm.startPrank(sender);
        mockERC20.mint(expectedTotalAmount);
        mockERC20.approve(address(tSender), expectedTotalAmount);
        vm.stopPrank();

        address[] memory recipients = new address[](numberOfRecipients);
        for (uint256 i = 0; i < numberOfRecipients; i++) {
            recipients[i] = address(uint160(i + 25));
        }
        uint256[] memory amounts = new uint256[](numberOfRecipients);
        for (uint256 i = 0; i < numberOfRecipients; i++) {
            amounts[i] = uint256Amount;
        }

        // Act
        vm.prank(sender);
        uint256 startingGas = gasleft();
        tSender.airdropERC20(address(mockERC20), recipients, amounts, expectedTotalAmount);
        uint256 gasUsed = startingGas - gasleft();
        console2.log("Gas used", gasUsed);

        // Assert
        for (uint256 i = 25; i < numberOfRecipients + 25; i++) {
            assertEq(mockERC20.balanceOf(address(uint160(i))), uint256Amount);
        }
    }

    function testAirdropERC20ToSingleUnit() public {
        _gasTest(1);
    }

    function testAirdropERC20ToTwoUnit() public {
        _gasTest(2);
    }

    function testAirDropErc20ToTen() public {
        _gasTest(10);
    }

    function testAirDropErc20ToManyUnit() public {
        _gasTest(100);
    }

    function testAirDropErc20OneThousand() public {
        _gasTest(1000);
    }

    /*//////////////////////////////////////////////////////////////
                                HELPERS
    //////////////////////////////////////////////////////////////*/

    // Remove duplicates from an array of addresses
    function _removeSpecialAddessesAndDuplicates(address[] memory recipients, address sender)
        private
        returns (address[] memory uniqueRecipients)
    {
        for (uint256 i = 0; i < recipients.length; i++) {
            // Remove zero addresses
            if (recipients[i] == address(0)) {
                continue;
            }
            // Remove sender address
            if (recipients[i] == sender) {
                continue;
            }
            recipientSet.add(recipients[i]);
        }
        uniqueRecipients = new address[](recipientSet.length());
        vm.assume(uniqueRecipients.length > 0);

        for (uint256 i = 0; i < recipientSet.length(); i++) {
            uniqueRecipients[i] = recipientSet.at(i);
        }
        return uniqueRecipients;
    }

    modifier hasSafetyChecks() {
        if (!_hasSafetyChecks) {
            return;
        }
        _;
    }
}
