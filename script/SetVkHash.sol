pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "forge-std/StdJson.sol";

import {BinVipHook} from "../src/pool-bin/BinVipHook.sol";

contract Deploy is Script {
    function run() public {
        address hookAddr = vm.envAddress("HOOK_ADDR");
        bytes32 vkhash = 0x00abe8e8da6b17cdf3dc6709562f39a4f6df9e54738203325a9aad293b7f3eb3;
        BinVipHook binHook = BinVipHook(hookAddr);
        
        vm.startBroadcast();
        binHook.setVkHash(vkhash);
        vm.stopBroadcast();
    }
}
