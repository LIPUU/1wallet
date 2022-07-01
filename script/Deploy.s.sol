// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "../src/1walletRouter.sol";

contract MyScript is Script {
    function run() external {
        vm.startBroadcast();

        Router router = new Router();

        vm.stopBroadcast();
    }
}