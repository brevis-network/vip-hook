pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "forge-std/StdJson.sol";

import {ITransparentUpgradeableProxy} from "../lib/openzeppelin-contracts/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

contract Deploy is Script {
    function run() public {
        address hookAddr = 0x45337f035B519ebBa5951Abf9263E39c9de0aB74;
        address newAdmin = 0xa500023551388763B720808C0b0CDf00A752b69f;
        ITransparentUpgradeableProxy proxy = ITransparentUpgradeableProxy(hookAddr);
        
        vm.startBroadcast();
        proxy.changeAdmin(newAdmin);
        vm.stopBroadcast();
    }
}