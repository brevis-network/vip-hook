pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "forge-std/StdJson.sol";

import {ITransparentUpgradeableProxy} from "../lib/openzeppelin-contracts/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

// can only be run by proxy admin
contract Deploy is Script {
    function run() public {
        address hookAddr = 0x45337f035B519ebBa5951Abf9263E39c9de0aB74;
        address newImpl = 0x0dD73765ddfD5570Db4A14137cA0E62EF81A8798;
        ITransparentUpgradeableProxy proxy = ITransparentUpgradeableProxy(hookAddr);
        
        vm.startBroadcast();
        proxy.upgradeTo(newImpl);
        vm.stopBroadcast();
    }
}