# TSender - Findings Report

[CodeHawks Link](https://codehawks.cyfrin.io/c/2024-05-TSender/results?lt=contest&page=1&sc=reward&sj=reward&t=leaderboard)
Commit hash: 0ffbb0dee2a66a6a0df3b31216520c32aba96081

# Table of contents
- ### [Contest Summary](#contest-summary)
- ### [Results Summary](#results-summary)

- ## Medium Risk Findings
    - [M-01. `TSender.huff` and `TSender_NoCheck.huff` contracts will transfer funds to wrong addresses when called with specific calldata.](#M-01)
- ## Low Risk Findings
    - [L-01. Unexpected protocol behavior because of some tokens have implementations only on part of the target chains](#L-01)


# <a id='contest-summary'></a>Contest Summary

### Sponsor: Cyfrin

### Dates: May 24th, 2024 - May 31st, 2024

[See more contest details here](https://codehawks.cyfrin.io/c/2024-05-TSender)

# <a id='results-summary'></a>Results Summary

### Number of findings:
   - High: 0
   - Medium: 1
   - Low: 1


# High Risk Findings



# Medium Risk Findings

## <a id='M-01'></a>M-01. `TSender.huff` and `TSender_NoCheck.huff` contracts will transfer funds to wrong addresses when called with specific calldata.

_Submitted by [Tricko](/profile/clk69ooo50012ms08mzsngte2)._      
            
### Relevant GitHub Links

https://github.com/Cyfrin/2024-05-TSender/blob/c6da9ef0c28741c007a02dfa07b7e899c1c22e47/src/protocol/TSender.huff#L115-L135

## Summary
Due to a mismatch of hardcoded and dynamic calldata offsets in the `TSender.huff` and `TSender_NoCheck.huff` contracts, both contracts transfer funds to incorrect addresses when called with specific calldata.

## Vulnerability Details
The Huff code (`TSender.huff` and `TSender_NoCheck.huff`) hardcodes certain calldata offset values (e.g., `RECIPIENT_ONE_OFFSET = 0xa4`). However, the offset of dynamic types like arrays is not fixed in calldata, leading to incorrect code execution if the calldata is formatted differently than expected.

The current ABI encoding used by Solidity and Vyper does not enforce a fixed order for dynamic type offsets. As a result, both calldata examples below are valid and decoded equivalently by the reference and Yul contracts (see POC below). However, while calldata A works as expected in the Huff contract, calldata B results in transfers to incorrect addresses.

```md
// Calldata A
//0x82947abe //selector "airdropERC20(address,address[],uint256[],uint256)"
//000000000000000000000000e87162786bb97c37c6e0f3a7077a7f0236580ea5 //erc20 address
//0000000000000000000000000000000000000000000000000000000000000080 //offset to the recipients array data
//00000000000000000000000000000000000000000000000000000000000000c0 //offset to the amounts array data
//0000000000000000000000000000000000000000000000000000000000000064 //totalAmount
//0000000000000000000000000000000000000000000000000000000000000001 //recipients length
//0000000000000000000000004dba461ca9342f4a6cf942abd7eacf8ae259108c //recipients data
//0000000000000000000000000000000000000000000000000000000000000001 //amounts length
//0000000000000000000000000000000000000000000000000000000000000064 //amount data
```

```md
// Calldata B
//0x82947abe //selector "airdropERC20(address,address[],uint256[],uint256)"
//000000000000000000000000e87162786bb97c37c6e0f3a7077a7f0236580ea5 //erc20 address
//00000000000000000000000000000000000000000000000000000000000000c0 //offset to the recipients array data
//0000000000000000000000000000000000000000000000000000000000000080 //offset to the amounts array data
//0000000000000000000000000000000000000000000000000000000000000064 //totalAmount
//0000000000000000000000000000000000000000000000000000000000000001 //amounts length
//0000000000000000000000000000000000000000000000000000000000000064 //amount data
//0000000000000000000000000000000000000000000000000000000000000001 //recipients length
//0000000000000000000000004dba461ca9342f4a6cf942abd7eacf8ae259108c //recipients data
```

At a [specific point](https://github.com/Cyfrin/2024-05-TSender/blob/c6da9ef0c28741c007a02dfa07b7e899c1c22e47/src/protocol/TSender.huff#L115-L135) in the Huff code, the difference between the `recipients` and `amounts` array offsets is computed for further use. However, due to the inversion of the `recipients` and `amounts` array offsets and the use of the hardcoded `NUMBER_OF_RECIPIENTS_OFFSET`, this difference becomes zero when calldata B is fed to `TSender.huff` (Check this scenario in [EVM Playground](https://www.evm.codes/playground?fork=cancun&unit=Wei&callData=0x82947abe000000000000000000000000e87162786bb97c37c6e0f3a7077a7f0236580ea500000000000000000000000000000000000000000000000000000000000000c0000000000000000000000000000000000000000000000000000000000000008000000000000000000000000000000000000000000000000000000000000000640000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000006400000000000000000000000000000000000000000000000000000000000000010000000000000000000000004dba461ca9342f4a6cf942abd7eacf8ae259108c&codeType=Bytecode&code=%2734yVx7h82947abepV7kh4d8m19ap0f4kqwwfdqwz0o4o0Zjxz8Yp048k6x0a3Vd6~ql23b872ddU33tn30R0nXoznwwXiwz0Yg7a5sla9059cbbUz8403z8o051bzaZza4q82mjxjwp0e6ktn03xjR0n85u9450wwRiw88gcxstummTy090kXY85_Sy0d9k00qllb625l~ql1647bca2~00qRYjjw_vz2o0Zx_Svwmmqp162ru5vmtVz2o2ZuxSvmWqj84pS6r2_vWy13956q5050Wmmy1T56qzuQxbwQ3%27~Uz0ifdX0y6Tx35w5fvy16bku01tz20s7lfaTea06~qrkjtVXZx8q5bp_yoYzn52m81l63k57j80i4z1chwxzeuclg5af1y0_14Z4uY4xXz6WzuuV02UwnT10S15Rz4QUtwf%01QRSTUVWXYZ_ghijklmnopqrstuvwxyz~_), the contract bytecode and calldata are already filled in). Consequently, when this difference is subtracted to obtain the correct offset of the current recipient element in the `recipients` array, the wrong offset is used. Thus, the current amount value at this offset is incorrectly used both as the amount and as the recipient of the ERC20 transactions (i.e instead of calling `transfer(0x4dba461ca9342f4a6cf942abd7eacf8ae259108c, 0x64)`, it calls `transfer(0x64, 0x64)`).

See the POC below. Note that the Huff contracts are not equivalent to the reference or Yul contracts. Although the same calldata is used to call all three contracts, `TSender.huff` and `TSender_NoCheck.huff` transfer tokens to the wrong recipient. Add the following code to the `/test` folder in the TSender repo and run it with `forge test`

```solidity
// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";
import {TSender} from "src/protocol/TSender.sol";
import {TSenderReference} from "src/reference/TSenderReference.sol";
import {MockERC20} from "test/mocks/MockERC20.sol";
import {HuffDeployer} from "lib/foundry-huff/src/HuffDeployer.sol";

contract POC is Test {
    TSender public huffTSender;
    TSender public yulTSender;
    TSender public solidityTSender;
    MockERC20 public mockERC20;
    address sender;
    address recipient;

    function setUp() public {
        solidityTSender = TSender(address(new TSenderReference()));
        string memory tsenderHuffLocation = "protocol/TSender"; // Change to protocol/TSender_NoCheck to test the huff no check contract
        huffTSender = TSender(HuffDeployer.config().deploy(tsenderHuffLocation));
        yulTSender = new TSender();
        
        MockERC20 contractERC20 = new MockERC20();
        address erc20 = makeAddr("ERC20"); //0xE87162786Bb97C37c6e0F3a7077A7F0236580EA5
        vm.etch(erc20, address(contractERC20).code);
        mockERC20 = MockERC20(erc20);

        sender = makeAddr("Alice");
        recipient = makeAddr("Bob"); //0x4dBa461cA9342F4A6Cf942aBd7eacf8AE259108C

        vm.startPrank(sender);
        mockERC20.mint(1e18);
        mockERC20.approve(address(huffTSender), type(uint256).max);
        mockERC20.approve(address(yulTSender), type(uint256).max);
        mockERC20.approve(address(solidityTSender), type(uint256).max);
        vm.stopPrank();
    }

    function testCalldataA() public {
        //0x82947abe
        //000000000000000000000000e87162786bb97c37c6e0f3a7077a7f0236580ea5
        //0000000000000000000000000000000000000000000000000000000000000080
        //00000000000000000000000000000000000000000000000000000000000000c0
        //0000000000000000000000000000000000000000000000000000000000000064
        //0000000000000000000000000000000000000000000000000000000000000001
        //0000000000000000000000004dba461ca9342f4a6cf942abd7eacf8ae259108c
        //0000000000000000000000000000000000000000000000000000000000000001
        //0000000000000000000000000000000000000000000000000000000000000064
        bytes memory callDataA = hex"82947abe000000000000000000000000e87162786bb97c37c6e0f3a7077a7f0236580ea5000000000000000000000000000000000000000000000000000000000000008000000000000000000000000000000000000000000000000000000000000000c0000000000000000000000000000000000000000000000000000000000000006400000000000000000000000000000000000000000000000000000000000000010000000000000000000000004dba461ca9342f4a6cf942abd7eacf8ae259108c00000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000064";

        vm.startPrank(sender);
        uint256 balanceBefore = mockERC20.balanceOf(recipient);
        (bool successReference, ) = address(solidityTSender).call(callDataA);
        assertEq(successReference, true);
        uint256 balanceAfter = mockERC20.balanceOf(recipient);
        assertEq(balanceAfter - balanceBefore, 100);

        balanceBefore = mockERC20.balanceOf(recipient);
        (bool successYul, ) = address(yulTSender).call(callDataA);
        require(successYul);
        assertEq(successYul, true);
        balanceAfter = mockERC20.balanceOf(recipient);
        assertEq(balanceAfter - balanceBefore, 100);

        balanceBefore = mockERC20.balanceOf(recipient);
        (bool successHuff, ) = address(huffTSender).call(callDataA);
        assertEq(successHuff, true);
        balanceAfter = mockERC20.balanceOf(recipient);
        assertEq(balanceAfter - balanceBefore, 100);
        vm.stopPrank();
    }

    function testCalldataB() public {
        //0x82947abe
        //000000000000000000000000e87162786bb97c37c6e0f3a7077a7f0236580ea5
        //00000000000000000000000000000000000000000000000000000000000000c0
        //0000000000000000000000000000000000000000000000000000000000000080
        //0000000000000000000000000000000000000000000000000000000000000064
        //0000000000000000000000000000000000000000000000000000000000000001
        //0000000000000000000000000000000000000000000000000000000000000064
        //0000000000000000000000000000000000000000000000000000000000000001
        //0000000000000000000000004dba461ca9342f4a6cf942abd7eacf8ae259108c
        bytes memory callDataB = hex"82947abe000000000000000000000000e87162786bb97c37c6e0f3a7077a7f0236580ea500000000000000000000000000000000000000000000000000000000000000c0000000000000000000000000000000000000000000000000000000000000008000000000000000000000000000000000000000000000000000000000000000640000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000006400000000000000000000000000000000000000000000000000000000000000010000000000000000000000004dba461ca9342f4a6cf942abd7eacf8ae259108c";

        vm.startPrank(sender);
        uint256 balanceBefore = mockERC20.balanceOf(recipient);
        (bool successReference, ) = address(solidityTSender).call(callDataB);
        assertEq(successReference, true);
        uint256 balanceAfter = mockERC20.balanceOf(recipient);
        assertEq(balanceAfter - balanceBefore, 100);

        balanceBefore = mockERC20.balanceOf(recipient);
        (bool successYul, ) = address(yulTSender).call(callDataB);
        require(successYul);
        assertEq(successYul, true);
        balanceAfter = mockERC20.balanceOf(recipient);
        assertEq(balanceAfter - balanceBefore, 100);

        balanceBefore = mockERC20.balanceOf(recipient);
        (bool successHuff, ) = address(huffTSender).call(callDataB);
        assertEq(successHuff, true);
        balanceAfter = mockERC20.balanceOf(recipient);
        // Assert that no fund was transferred to recipient address
        assertEq(balanceAfter - balanceBefore, 0);
        
        // Assert that funds were transferred to address 0x64 instead
        assertEq(mockERC20.balanceOf(address(0x64)), 100);
        vm.stopPrank();
    }
}
```

## Impact
`TSender.huff` and `TSender_NoCheck.huff` contracts will transfer funds to wrong addresses when called with specific calldata.

## Tools Used 
Manual Review.

## Recommendations
Do not use hardcoded offsets for any of the dynamic types (`address[] recipients` and `uint256[] amounts`).


# Low Risk Findings

## <a id='L-01'></a>L-01. Unexpected protocol behavior because of some tokens have implementations only on part of the target chains

_Submitted by [pontifex](/profile/clk3xo3e0000omm08i6ehw2ae)._      
            
### Relevant GitHub Links

https://github.com/Cyfrin/2024-05-TSender/blob/main/src/protocol/TSender.sol

https://github.com/Cyfrin/2024-05-TSender/blob/main/src/protocol/TSender.huff

https://github.com/Cyfrin/2024-05-TSender/blob/main/src/protocol/TSender_NoCheck.huff

## Summary
USDT, USDC and LINK tokens have no implementations on some of the target deployment chains. So there is no guarantee of correct integration when the implementations will appear.
## Vulnerability Details
According to the contest documentation expected token integrations are USDT, USDC, LINK and WETH, and target deployment chains are zkSync Era, Ethereum, Arbitrum, Optimism, Base and Blast. 

Unfortunately only WETH token has implementations on all listed chains currently.

In turn LINK and USDC have no implementations on Blast chain (https://docs.chain.link/resources/link-token-contracts, https://www.circle.com/en/multi-chain-usdc). 

USDT has no trusted implementations on Base and Blast chains (https://basescan.org/tokens , https://blastscan.io/tokens).

Since the implementations are absent no one can guarantee the protocol can integrate with them.

## Impact
Though the likelihood of unsupported implementations appearing is low the potential impact, e.g. asset losses, is high.

## Tools used
Manual Review

## Recommendations
Consider reducing the list of supported tokens on Base and Blast chains according to the provided information. 




    