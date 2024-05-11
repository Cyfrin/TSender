# TSender

- [TSender](#tsender)
- [About](#about)
  - [TSender Features](#tsender-features)
  - [GasliteDrop Comparison](#gaslitedrop-comparison)
  - [Gas Comparisons](#gas-comparisons)
    - [Vs GasliteDrop](#vs-gaslitedrop)
- [Getting Started](#getting-started)
  - [Requirements](#requirements)
  - [Installation](#installation)
  - [Quickstart / Usage](#quickstart--usage)
    - [Testing](#testing)
      - [Why no stateful fuzz tests?](#why-no-stateful-fuzz-tests)
    - [Deployment](#deployment)
- [Audit Data](#audit-data)
  - [Known issues](#known-issues)
  - [Expected Token Integrations](#expected-token-integrations)
  - [Scope](#scope)
  - [Chain compatibility](#chain-compatibility)
    - [Target deployment chains](#target-deployment-chains)
  - [Notes](#notes)
- [Acknowledgements](#acknowledgements)
- [Future (Huff) gas optimization](#future-huff-gas-optimization)

# About

Hyper gas efficient smart contracts for air dropping tokens to a large number of users. Inspired by the work of the [Gaslite team](https://github.com/PopPunkLLC/GasliteDrop/tree/main). In the `src` folder, we have 4 main contracts:
- `TSender.sol`: The Yul/Solidity implementation 
- `TSender.huff`: The Huff implementation
- `TSender_NoCheck.huff`: The Huff implementation without the extra checks, making the output similar to `GasliteDrop`
- `TSenderReference.sol`: The pure Solidity implementation

Each contract has exactly 1 function:
- `airdropERC20`: A function that takes in an array of recipients and an array of amounts, and sends the amounts to the recipients.

## TSender Features 
- Checks the `totalAmount` parameter matches the sum of the `amounts` array
- Doesn't allow ETH to be sent with function calls
- Makes sure the total lengths of the `amounts` array and `recipients` array are the same

## GasliteDrop Comparison

The work here was inspired by the [Gaslite team](https://github.com/PopPunkLLC/GasliteDrop/tree/main) with a few changes.

1. The Yul & Huff have added safety checks (see [TSender Features](#tsender-features))
2. The `TSender_NoCheck.huff` does not have the extra checks, but is just a gas optimized version of the original GasliteDrop contract.

## Gas Comparisons
### Vs GasliteDrop
Since our implementation adds more checks, the Huff code is actually slightly *less* gas efficient, but it is a safer smart contract. However, we did include a Huff contract the did not include those checks to show the power of using Huff to reduce gas costs.



# Getting Started

## Requirements 

- [git](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git)
  - You'll know you did it right if you can run `git --version` and you see a response like `git version x.x.x`
- [foundry](https://getfoundry.sh/)
  - You'll know you did it right if you can run `forge --version` and you see a response like `forge 0.2.0 (816e00b 2023-03-16T00:05:26.396218Z)`
- [foundry-zksync](https://github.com/matter-labs/foundry-zksync)
  - You'll know you did it right if you can run `forge --version` and you see a response like `forge 0.0.2 (816e00b 2023-03-16T00:05:26.396218Z)`
- [halmos](https://github.com/a16z/halmos)
  - You'll know you've done it right if you can run `halmos --version` and you see a response like `Halmos 0.1.12`

## Installation

```
git clone https://github.com/cyfrin/tsender
cd tsender
make
```

## Quickstart / Usage


### Testing

To test the codebase, you can run the following 3 commands:

```bash
make test
make zktest
make halmos
```

#### Why no stateful fuzz tests?

Our contract is expected to never have state. There are no `SSTORE` opcodes in the bytecode of this contract.

### Deployment

You'll need to uncomment out the `DeployHuff.s.sol` codebase. It's commented out because zkSync has a hard time compiling it at the moment. This is ok because we do not intend to deploy huff to zksync. 

```
make deployYul 
make deployHuff
```

# Audit Data

## Known issues
- Does not work with fee-on-transfer tokens
- Does not check the return value of ERC20s, but it does check to see if the `transferFrom` or `transfer` call was successful. Meaning ERC20s that return `false` on a failed `transfer` or `transferFrom` but successfully execute, are not supported. If any of the expected token integrations are vulnerable to this pattern, flag it. 
- Upgradable/Deny List tokens can prevent this contract from working. We expect that, in the case that this contract or any recipient is on a deny list, the entire transaction will revert. 

## Expected Token Integrations
- USDC 
- USDT
- LINK
- WETH

## Scope

```bash
#-- interfaces
|   #-- ITSender.sol
#-- protocol
|   #-- TSender.huff
|   #-- TSender.sol
```

Ignore:
```bash
#-- protocol
|   #-- TSender_NoCheck.huff
#-- reference
    #-- TSenderReference.sol
```

## Chain compatibility

We expect to be able to run our deploy scripts, and it will prevent us from deploying contracts to chains that are not supported. Right now, zkSync will work with the `yul` based `TSender.sol`, and all other chains listed in the `HelperConfig.sol` will work with the `TSender.huff` contract. 

### Target deployment chains
- Ethereum:
  - `TSender.huff`
- zkSync:
  - `TSender.sol`


## Notes
- There is an issue with how quickly the `foundry-zksync` compiler works, so we avoid compiling the `DeployHuff.s.sol` contract. 
- Compliation takes a *long* time, so run tests accordingly. It may make sense to run tests with the standard foundry implementation before swapping to the `foundry-zksync` implementation.

# Acknowledgements
- [Gaslite](https://github.com/PopPunkLLC/GasliteDrop)
- [PopPunkOnChain](https://twitter.com/PopPunkOnChain)
- [Vectorized](https://github.com/Vectorized/)
- [backseats_eth](https://twitter.com/backseats_eth)

# Future (Huff) gas optimization
- Turn `NUMBER_OF_AMOUNTS_OFFSET_MEMORY_LOCATION` into a stack variable