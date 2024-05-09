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


# Known issues
- Does not work with fee-on-transfer tokens
- Does not check the return value of ERC20s, but it does check to see if the `transferFrom` or `transfer` call was successful