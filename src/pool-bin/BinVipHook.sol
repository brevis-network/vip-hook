// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {LPFeeLibrary} from "@pancakeswap/v4-core/src/libraries/LPFeeLibrary.sol";
import {PoolKey} from "@pancakeswap/v4-core/src/types/PoolKey.sol";
import {BalanceDelta} from "@pancakeswap/v4-core/src/types/BalanceDelta.sol";
import {BeforeSwapDelta, BeforeSwapDeltaLibrary} from "@pancakeswap/v4-core/src/types/BeforeSwapDelta.sol";
import {PoolId, PoolIdLibrary} from "@pancakeswap/v4-core/src/types/PoolId.sol";
import {IBinDynamicFeeManager} from "@pancakeswap/v4-core/src/pool-bin/interfaces/IBinDynamicFeeManager.sol";
import {IBinPoolManager} from "@pancakeswap/v4-core/src/pool-bin/interfaces/IBinPoolManager.sol";
import {BinBaseHook} from "./BinBaseHook.sol";
import {VipDiscountMap} from "../VipDiscountMap.sol";
import {BrevisApp} from "../BrevisApp.sol";
import {Ownable} from "../Ownable.sol";

/// @notice BinVipHook is a contract that provides fee discount based on VIP tiers
contract BinVipHook is IBinDynamicFeeManager, BinBaseHook, VipDiscountMap, BrevisApp, Ownable {
    using PoolIdLibrary for PoolKey;
    event FeeUpdated(uint24 fee);
    event BrevisReqUpdated(address addr);
    event VkHashUpdated(bytes32 vkhash);

    // need this to proper tracking "user"
    event TxOrigin(address indexed addr); // index field to save zk parsinig cost

    bytes32 public vkHash; // BrevisApp to ensure correct circuit

    // no vkhash as we expect it's set later by proxy or setVkHash
    constructor(IBinPoolManager _poolManager, uint24 _origFee, address _brevisRequest) BinBaseHook(_poolManager) BrevisApp(_brevisRequest) {
        origFee = _origFee;
    }

    // called by proxy to properly set storage of proxy contract
    function init(uint24 _origFee, address _brevisRequest, bytes32 _vkHash) external {
        initOwner(); // will fail if not called via delegateCall b/c owner is set in Ownable constructor
        // no need to emit event as it's first set in proxy state
        _setBrevisRequest(_brevisRequest);
        origFee = _origFee;
        vkHash = _vkHash;
    }

    function getHooksRegistrationBitmap() external pure override returns (uint16) {
        return _hooksRegistrationBitmapFrom(
            Permissions({
                beforeInitialize: false,
                afterInitialize: false,
                beforeMint: false,
                afterMint: false,
                beforeBurn: false,
                afterBurn: false,
                beforeSwap: true,  // only beforeSwap
                afterSwap: false,
                beforeDonate: false,
                afterDonate: false,
                beforeSwapReturnsDelta: false,
                afterSwapReturnsDelta: false,
                afterMintReturnsDelta: false,
                afterBurnReturnsDelta: false
            })
        );
    }

    // afterInitialize poolManager.updateDynamicLPFee

    function beforeSwap(address, PoolKey calldata key, bool, uint128, bytes calldata)
        external
        override
        poolManagerOnly
        returns (bytes4, BeforeSwapDelta, uint24)
    {
        uint24 dynFee = getFee(tx.origin);
        emit TxOrigin(tx.origin);
        return (this.beforeSwap.selector, BeforeSwapDeltaLibrary.ZERO_DELTA, dynFee | LPFeeLibrary.OVERRIDE_FEE_FLAG);
    }

    // satisfy IBinDynamicFeeManager. caller should set msg.sender to actual user address for accurate result
    function getFeeForSwapInSwapOut(address usr, PoolKey calldata, bool, uint128, uint128) external view returns (uint24) {
        return getFee(usr);
    }

    // brevisApp interface
    function handleProofResult(bytes32 _vkHash, bytes calldata _appCircuitOutput) internal override {
        require(vkHash == _vkHash, "invalid vk");
        updateBatch(_appCircuitOutput);
    }

    function setFee(uint24 _newfee) external onlyOwner {
        origFee = _newfee;
        emit FeeUpdated(_newfee);
    }

    function setVkHash(bytes32 _vkh) external onlyOwner {
        vkHash = _vkh;
        emit VkHashUpdated(_vkh);        
    }

    function setBrevisRequest(address _brevisRequest) external onlyOwner {
        _setBrevisRequest(_brevisRequest);
        emit BrevisReqUpdated(_brevisRequest);
    }
}
