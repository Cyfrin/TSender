// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Script, console2} from "forge-std/Script.sol";
import {HuffDeployer, HuffConfig} from "lib/foundry-huff/src/HuffDeployer.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";

contract DeployHuff is Script {
    string public constant tsenderHuffLocation = "protocol/TSender";

    function run() public {
        HuffConfig huffConfig = HuffDeployer.config();
        HelperConfig helperConfig = new HelperConfig();

        if (helperConfig.isValidChain(block.chainid, helperConfig.getHuffCompatibleChains()) == false) {
            revert HelperConfig.HelperConfig__InvalidChainId();
        }

        vm.startBroadcast();
        address huffTSender = deployHuff(huffConfig);
        vm.stopBroadcast();

        console2.log("TSender Huff deployed to:", huffTSender);
    }

    function deployHuff(HuffConfig config) public returns (address) {
        return config.deploy(tsenderHuffLocation);
    }
}
