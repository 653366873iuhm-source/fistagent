// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console2} from "forge-std/Script.sol";
import {BscConfig} from "./BscConfig.sol";
import {FistagentMint} from "../src/FistagentMint.sol";

/// @notice FISTAGENT v2: plain CREATE from the deployer EOA (becomes `operator`, pause-only). Mint starts PAUSED.
contract DeployV2 is Script {
    function run() external {
        vm.startBroadcast();
        require(msg.sender == BscConfig.DEPLOYER, "wrong deployer");
        FistagentMint m = new FistagentMint(BscConfig.params(BscConfig.SOCIAL_SIGNER));
        vm.stopBroadcast();
        console2.log("mint", address(m));
        console2.log("token", address(m.token()));
        console2.log("pair", address(m.pair()));
    }
}
