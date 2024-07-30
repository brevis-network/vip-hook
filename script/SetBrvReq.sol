pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "forge-std/StdJson.sol";

import {BinVipHook} from "../src/pool-bin/BinVipHook.sol";

contract Deploy is Script {
    function run() public {
        address hookAddr = vm.envAddress("HOOK_ADDR");
        address brvReq = 0xF7E9CB6b7A157c14BCB6E6bcf63c1C7c92E952f5;
        BinVipHook binHook = BinVipHook(hookAddr);
        
        vm.startBroadcast();
        binHook.setBrevisRequest(brvReq);
        vm.stopBroadcast();
    }
}