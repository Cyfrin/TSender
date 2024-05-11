// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Script, console2} from "forge-std/Script.sol";
import {TSender} from "src/protocol/TSender.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";

contract DeployYul is Script {
    function run() public {
        HelperConfig helperConfig = new HelperConfig();

        if (helperConfig.isValidChain(block.chainid, helperConfig.getYulCompatibleChains()) == false) {
            revert HelperConfig.HelperConfig__InvalidChainId();
        }

        vm.startBroadcast();
        TSender tSender = deployYul();
        vm.stopBroadcast();

        console2.log("TSender Yul deployed to:", address(tSender));
    }

    function deployYul() public returns (TSender) {
        return new TSender();
    }
}
