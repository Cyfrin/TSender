_This repo is a work in progress_

# TSender

## About

Hyper gas efficient smart contracts for air dropping tokens to a large number of users. Inspired by the work of the [Gaslite team](https://github.com/PopPunkLLC/GasliteDrop/tree/main).

## Features 
- Huff Implementation
- Vyper Implementation
- Solidity Reference Implementation
- Solidity & Assembly Implementation

# Gas Comparisons

# TSender (Assembly) Features 
- Checks the `totalAmount` parameter matches the sum of the `amounts` array
- Doesn't allow ETH to be sent with function calls
- Does not check the `bool` return value of the `transferFrom` or `transfer` calls

# TSender (Yul) Features

# Known issues
- Does not work with fee-on-transfer tokens
- Does not check the return value of ERC20s, but it does check to see if the `transferFrom` or `transfer` call was successful

# Future (Huff) gas optimization
- Use more `DUP1` opcodes to load calldata instead of `PUSHX CALLDATALOAD` everywhere
- Expand memory fewer, which incurs [memory expansion gas costs](https://www.evm.codes/about#memoryexpansion)
    - When we do the `transfer`, we have memory location `c0` and `e0` free, and that's a waste of gas. Can move everything back by 2 memory slots (aka, 64 bytes)