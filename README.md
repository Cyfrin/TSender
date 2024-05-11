_This repo is a work in progress_

# TSender

- [TSender](#tsender)
  - [About](#about)
- [Features](#features)
  - [TSender (Huff) Features](#tsender-huff-features)
  - [Future (Huff) gas optimization](#future-huff-gas-optimization)
- [Gas Comparisons](#gas-comparisons)
  - [Vs GasliteDrop](#vs-gaslitedrop)
- [Known issues](#known-issues)

## About

Hyper gas efficient smart contracts for air dropping tokens to a large number of users. Inspired by the work of the [Gaslite team](https://github.com/PopPunkLLC/GasliteDrop/tree/main).

# Features 
- Solidity Reference Implementation
- Solidity & Yul Implementation
- Huff Implementation

## TSender (Huff) Features 
- Checks the `totalAmount` parameter matches the sum of the `amounts` array
- Doesn't allow ETH to be sent with function calls


## Future (Huff) gas optimization
- Turn `NUMBER_OF_AMOUNTS_OFFSET_MEMORY_LOCATION` into a stack variable

# Gas Comparisons
## Vs GasliteDrop
- Compared to [GasliteDrop](https://github.com/PopPunkLLC/GasliteDrop) we:
  - Saved `579` gas
  - Added checks for:
    - Length of `recipients` and `amounts` arrays
    - Doesn't allow ETH to be sent with function calls

# Known issues
- Does not work with fee-on-transfer tokens
- Does not check the return value of ERC20s, but it does check to see if the `transferFrom` or `transfer` call was successful. Meaning ERC20s that return `false` on a failed `transfer` or `transferFrom` but successfully execute, are not supported
- Does not check the `bool` return value of the `transferFrom` or `transfer` calls