// // SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";
import {SymTest} from "lib/halmos-cheatcodes/src/SymTest.sol";
import {TSender} from "src/protocol/TSender.sol";
import {TSenderReference} from "src/reference/TSenderReference.sol";
import {MockERC20} from "test/mocks/MockERC20.sol";

// I think for a lot of this, the invariants are going to run into path explosion
// Because of this, fuzzing is likely a better solution. When we run our fuzz tests,
// all the tests in this folder will get picked up too. There are a few scenarios
// where formal verification can give us a lot more assurance though.

// Invariants:
// 1. Calling `airdropERC20` with the same valid arguments should result in the exact same states changes in all contracts

// Rules:
// 1. If `areValidLists` reverts in Solc or Yul, the Huff must revert or return false
// 2. If `areValidLists` returns true in Solc or Yul, the Huff must
// 3. If value is sent in any of the contracts via `airdropERC20`, the function must revert
contract EquivalenceTest is SymTest, Test {
    TSender public huffTSender;
    TSender public yulTSender;
    TSender public solidityTSender;
    MockERC20 public mockERC20;

    uint256 constant ONE = 1e18;
    uint256 constant AMOUNT_OF_COMPARING_CONTRACTS = 3;

    function setUp() public {
        // We have to deploy our huff contract a slightly different way for Halmos to work
        // Copy the text from compiled_huff.txt and put it in here
        // This does not include the contract creation code
        // huffc src/protocol/TSender.huff --bytecode > compiled_huff.txt
        bytes memory deployBytecode =
            hex"61017380600a3d393df334610023575f3560e01c6382947abe14610027575f3560e01c634d88119a146100f4575b5f5ffd5b5f600435604435600401803560843514610048576350a302d65f526004601cfd5b6323b872dd5f5233602052306040526064356060525f5f6064601c5f6004355af161007a5763fa10ea065f526004601cfd5b63a9059cbb5f5260840360843560051b60a40160a45b82818035805f146100e657602052033580604052850194505f5f6044601c5f885af16100c35763fa10ea065f526004601cfd5b602001818110610090576064358514156100d957005b6363b625635f526004601cfd5b631647bca25f526004601cfd005b60443580805f1461016b5760243560040135141561016b575f81815b14610162578060200260640135801561016b578160200260243560240101351561016b57816001015b808414610156578060200260640135821461016b57600101610139565b50506001018181610110565b60015f5260205ff35b5f5f5260205ff3";
        address tSenderHuffAddr;
        assembly {
            tSenderHuffAddr := create(0, add(deployBytecode, 0x20), mload(deployBytecode))
        }

        solidityTSender = TSender(address(new TSenderReference()));
        huffTSender = TSender(tSenderHuffAddr);
        yulTSender = new TSender();
        mockERC20 = new MockERC20();
    }

    // halmos --function testEachShouldSendTheExactAmount --solver-timeout-assertion 0
    function testEachShouldSendTheExactAmount(address sender, uint128 amountCapped, address recipient) public {
        vm.assume(recipient != address(0));
        vm.assume(sender != address(0));
        uint256 amount = uint256(amountCapped);
        uint256 totalAmount = amount * AMOUNT_OF_COMPARING_CONTRACTS;

        vm.startPrank(sender);
        mockERC20.mint(totalAmount);
        mockERC20.approve(address(huffTSender), totalAmount);
        mockERC20.approve(address(yulTSender), totalAmount);
        mockERC20.approve(address(solidityTSender), totalAmount);
        vm.stopPrank();

        address[] memory recipients = new address[](1);
        recipients[0] = recipient;
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = uint256(amount);

        vm.startPrank(sender);
        yulTSender.airdropERC20(address(mockERC20), recipients, amounts, uint256(amount));
        huffTSender.airdropERC20(address(mockERC20), recipients, amounts, uint256(amount));
        solidityTSender.airdropERC20(address(mockERC20), recipients, amounts, uint256(amount));
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
        mockERC20.approve(address(solidityTSender), amount);
        vm.stopPrank();

        address[] memory recipients = new address[](1);
        recipients[0] = recipient;
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = amount;

        bytes4 selector = TSender.airdropERC20.selector;
        bytes memory data = abi.encodeWithSelector(selector, address(mockERC20), recipients, amounts, amount);

        // Act
        vm.deal(address(this), amount * AMOUNT_OF_COMPARING_CONTRACTS);
        (bool succYul,) = address(yulTSender).call{value: amount}(data);
        (bool succHuff,) = address(huffTSender).call{value: amount}(data);
        (bool succSolidity,) = address(solidityTSender).call{value: amount}(data);
        assert(succYul == succHuff);
        assert(succYul == succSolidity);
    }

    // halmos --function testAreListsValidAlwaysOutputEquallyForSolcAndYul --solver-timeout-assertion 0
    function testAreListsValidAlwaysOutputEquallyForSolcAndYul(bytes calldata data) public {
        bytes memory dataToSender = abi.encodeWithSelector(TSender.areListsValid.selector, data);
        (bool yulSuccess, bytes memory yulResponse) = address(yulTSender).call(dataToSender);
        (bool soliditySuccess, bytes memory solidityResponse) = address(solidityTSender).call(dataToSender);

        assert(yulSuccess == soliditySuccess);
        assert(bytes32(yulResponse) == bytes32(solidityResponse));
    }

    // halmos --function testSolidInputsResultInTheSameOutputsFuzz --solver-timeout-assertion 0
    function testSolidInputsResultInTheSameOutputsFuzz(address[] calldata recipients, uint256[] calldata amounts)
        public
        view
    {
        bytes memory dataToSender = abi.encodeWithSelector(TSender.areListsValid.selector, recipients, amounts);
        (bool yulSuccess, bytes memory yulResponse) = address(yulTSender).staticcall(dataToSender);
        (bool huffSuccess, bytes memory huffResponse) = address(huffTSender).staticcall(dataToSender);
        (bool soliditySuccess, bytes memory solidityResponse) = address(solidityTSender).staticcall(dataToSender);
        assert(yulSuccess == huffSuccess);
        assert(yulSuccess == soliditySuccess);
        assert(bytes32(yulResponse) == bytes32(solidityResponse));
        assert(bytes32(yulResponse) == bytes32(huffResponse));
    }

    // This is also not a halmos test
    function testSolidInputsResultInTheSameOutputsUnit() public view {
        address[] memory recipients = new address[](2);
        recipients[0] = address(0x0000000000000000000000000000000000000001);
        recipients[1] = address(0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF);

        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 115792089237316195423570985008687907853269984665640564039457584007913129639935;
        amounts[1] = 0;

        bytes memory dataToSender = abi.encodeWithSelector(TSender.areListsValid.selector, recipients, amounts);
        (bool yulSuccess, bytes memory yulResponse) = address(yulTSender).staticcall(dataToSender);
        (bool soliditySuccess, bytes memory solidityResponse) = address(solidityTSender).staticcall(dataToSender);
        (bool huffSuccess, bytes memory huffResponse) = address(huffTSender).staticcall(dataToSender);
        assert(yulSuccess == huffSuccess);
        assert(yulSuccess == soliditySuccess);
        assert(bytes32(yulResponse) == bytes32(solidityResponse));
        assert(bytes32(yulResponse) == bytes32(huffResponse));
    }

    /*//////////////////////////////////////////////////////////////
                         FUZZ EQUIVALENCE TESTS
    //////////////////////////////////////////////////////////////*/
    // We do not run this as a halmos test, only a fuzz test
    function testIfAreListsValidRevertsHuffAtLeastReturnsFalse(bytes calldata data) public {
        bytes memory dataToSender = abi.encodeWithSelector(TSender.areListsValid.selector, data);
        (bool yulSuccess, bytes memory yulResponse) = address(yulTSender).call(dataToSender);
        (bool huffSuccess, bytes memory huffResponse) = address(huffTSender).call(dataToSender);

        if (!yulSuccess) {
            if (huffSuccess) {
                assert(bytes32(huffResponse) == bytes32(uint256(0))); // bytes32(0) is false in bytes
            } else {
                assert(bytes32(yulResponse) == bytes32(huffResponse));
            }
        } else {
            assert(!huffSuccess);
        }
    }

    // We do not run this as a halmos test, only a fuzz test
    function testAirdropErc20HasEqualOutputs(
        address[] calldata recipients,
        uint256[] calldata amounts,
        uint128 totalAmount,
        address sender
    ) public {
        vm.assume(
            sender != address(0) && sender != address(this) && sender != address(yulTSender)
                && sender != address(huffTSender) && sender != address(solidityTSender)
        );

        vm.startPrank(sender);
        mockERC20.mint(uint256(totalAmount) * AMOUNT_OF_COMPARING_CONTRACTS);
        mockERC20.approve(address(yulTSender), uint256(totalAmount));
        mockERC20.approve(address(huffTSender), uint256(totalAmount));
        mockERC20.approve(address(solidityTSender), uint256(totalAmount));

        bytes memory dataToSender = abi.encodeWithSelector(
            TSender.airdropERC20.selector, address(mockERC20), recipients, amounts, uint256(totalAmount)
        );
        (bool yulSuccess,) = address(yulTSender).call(dataToSender);
        (bool huffSuccess,) = address(huffTSender).call(dataToSender);
        (bool soliditySuccess,) = address(solidityTSender).call(dataToSender);
        vm.stopPrank();

        assert(yulSuccess == huffSuccess);
        assert(yulSuccess == soliditySuccess);
        if (yulSuccess) {
            for (uint256 i; i < recipients.length; i++) {
                assert(mockERC20.balanceOf(recipients[i]) == amounts[i] * AMOUNT_OF_COMPARING_CONTRACTS);
            }
        }
    }

    // We do not run this as a halmos test, only a fuzz test
    function testMultiSendResultsInSameSuccess(uint128 totalAmountCapped, address sender, uint256 modSeed) public {
        vm.assume(sender != address(0));
        vm.assume(modSeed != 0);
        uint256 totalAmount = uint256(totalAmountCapped);
        uint256 numberOfRecipients = 4;

        // Arrange
        vm.startPrank(sender);
        mockERC20.mint(totalAmount * AMOUNT_OF_COMPARING_CONTRACTS);
        mockERC20.approve(address(yulTSender), totalAmount);
        mockERC20.approve(address(huffTSender), totalAmount);
        mockERC20.approve(address(solidityTSender), totalAmount);
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
        (bool succSolidity,) = address(solidityTSender).call(data);
        vm.stopPrank();

        // Assert
        assert(succYul == succHuff);
        assert(succYul == succSolidity);
        assert(mockERC20.balanceOf(recipients[0]) == amounts[0] * AMOUNT_OF_COMPARING_CONTRACTS);
        assert(mockERC20.balanceOf(recipients[1]) == amounts[1] * AMOUNT_OF_COMPARING_CONTRACTS);
        assert(mockERC20.balanceOf(recipients[2]) == amounts[2] * AMOUNT_OF_COMPARING_CONTRACTS);
        assert(mockERC20.balanceOf(recipients[3]) == amounts[3] * AMOUNT_OF_COMPARING_CONTRACTS);
    }
}
