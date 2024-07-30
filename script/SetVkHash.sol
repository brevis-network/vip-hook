pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "forge-std/StdJson.sol";

import {BinVipHook} from "../src/pool-bin/BinVipHook.sol";

contract Deploy is Script {
    function run() public {
        address hookAddr = vm.envAddress("HOOK_ADDR");
        bytes32 vkhash = 0x0fe1d819796cb0ebb1a30a613e8cd425619c0d73e52d62dc2298435994f9927a;
        BinVipHook binHook = BinVipHook(hookAddr);
        
        vm.startBroadcast();
        binHook.setVkHash(vkhash);
        vm.stopBroadcast();
    }
}