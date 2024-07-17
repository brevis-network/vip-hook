pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "forge-std/StdJson.sol";

// import {BrevisFee} from "../src/BrevisFeeVault.sol";
import {BinVipHook,IBinPoolManager} from "../src/pool-bin/BinVipHook.sol";
import {CLVipHook,ICLPoolManager} from "../src/pool-cl/CLVipHook.sol";

/**
 * forge script script/Deploy.s.sol:Deploy -vvv \
 *     --rpc-url $RPC_URL \
 *     --private-key $PRIVATE_KEY
 *     --broadcast \
 *     --slow \
 *     --verify
 */
contract Deploy is Script {
    string public deployConfigPath = string.concat("script/config/bsctest.json");

    function run() public {
        string memory config = vm.readFile(deployConfigPath);
        address brevReq = stdJson.readAddress(config, ".brevisRequest");
        address clpm = stdJson.readAddress(config, ".clPoolManager");
        address binpm = stdJson.readAddress(config, ".binPoolManager");

        vm.startBroadcast();

        //BrevisFee feev = new BrevisFee();
        //console.log("BrevisFee contract deployed at ", address(feev));

        BinVipHook binHook = new BinVipHook(IBinPoolManager(binpm), 0, brevReq);
        console.log("binHook contract deployed at ", address(binHook));

        CLVipHook clHook = new CLVipHook(ICLPoolManager(clpm), 0, brevReq);
        console.log("clHook contract deployed at ", address(clHook));
        
        vm.stopBroadcast();
    }
}