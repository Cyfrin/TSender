// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Script} from "forge-std/Script.sol";

contract HelperConfig is Script {
    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/
    error HelperConfig__InvalidChainId();

    /*//////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/
    uint256[] public yulCompatibleChains = [ZKSYNC_MAINNET_CHAIN_ID, ZKSYNC_SEPOLIA_CHAIN_ID];

    uint256[] public huffCompatibleChains = [
        ANVIL_CHAIN_ID,
        ETH_MAINNET_CHAIN_ID,
        ETH_SEPOLIA_CHAIN_ID,
        // POLYGON_MAINNET_CHAIN_ID,
        ARB_MAINNET_CHAIN_ID,
        OP_MAINNET_CHAIN_ID,
        BASE_MAINNET_CHAIN_ID,
        BLAST_MAINNET_CHAIN_ID
        // LINEA_MAINNET_CHAIN_ID
    ];

    /*//////////////////////////////////////////////////////////////
                        ONLY SOLIDITY COMPATIBLE
    //////////////////////////////////////////////////////////////*/
    uint256 constant ZKSYNC_MAINNET_CHAIN_ID = 324;
    uint256 constant ZKSYNC_SEPOLIA_CHAIN_ID = 300;

    /*//////////////////////////////////////////////////////////////
                            HUFF COMPATIBLE
    //////////////////////////////////////////////////////////////*/
    uint256 constant ANVIL_CHAIN_ID = 1337;

    uint256 constant ETH_MAINNET_CHAIN_ID = 1;
    uint256 constant ETH_SEPOLIA_CHAIN_ID = 11_155_111;

    uint256 constant ARB_MAINNET_CHAIN_ID = 42161;
    uint256 constant OP_MAINNET_CHAIN_ID = 10;
    uint256 constant BASE_MAINNET_CHAIN_ID = 8453;
    uint256 constant BLAST_MAINNET_CHAIN_ID = 81457;
    // uint256 constant LINEA_MAINNET_CHAIN_ID = 112233; does not support push0

    /*//////////////////////////////////////////////////////////////
                               FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    constructor() {
        for (uint256 i; i < huffCompatibleChains.length; i++) {
            yulCompatibleChains.push(huffCompatibleChains[i]);
        }
    }

    function getHuffCompatibleChains() public view returns (uint256[] memory) {
        return huffCompatibleChains;
    }

    function getYulCompatibleChains() public view returns (uint256[] memory) {
        return yulCompatibleChains;
    }

    function isValidChain(uint256 chainId, uint256[] memory chainList) public pure returns (bool) {
        for (uint256 i = 0; i < chainList.length; i++) {
            if (chainList[i] == chainId) {
                return true;
            }
        }
        return false;
    }
}
