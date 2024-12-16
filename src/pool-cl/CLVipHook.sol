// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {LPFeeLibrary} from "@pancakeswap/v4-core/src/libraries/LPFeeLibrary.sol";
import {PoolKey} from "@pancakeswap/v4-core/src/types/PoolKey.sol";
import {BalanceDelta} from "@pancakeswap/v4-core/src/types/BalanceDelta.sol";
import {BeforeSwapDelta, BeforeSwapDeltaLibrary} from "@pancakeswap/v4-core/src/types/BeforeSwapDelta.sol";
import {PoolId, PoolIdLibrary} from "@pancakeswap/v4-core/src/types/PoolId.sol";
import {ICLPoolManager} from "@pancakeswap/v4-core/src/pool-cl/interfaces/ICLPoolManager.sol";
import {CLBaseHook} from "./CLBaseHook.sol";
import {VipDiscountMap} from "../VipDiscountMap.sol";
import {BrevisApp} from "../BrevisApp.sol";
import {Ownable} from "../Ownable.sol";

/// @notice CLVipHook is a contract that provides fee discount based on VIP tiers
contract CLVipHook is CLBaseHook, VipDiscountMap, BrevisApp, Ownable {
    using PoolIdLibrary for PoolKey;
    event FeeUpdated(uint24 fee);
    event BrevisReqUpdated(address addr);
    event VkHashAdded(bytes32 vkhash);
    event VkHashRemoved(bytes32 vkhash);

    // need this to proper tracking "user"
    event TxOrigin(address indexed addr); // index field to save zk parsinig cost

    // supported vkhash
    mapping(bytes32 => bool) public vkmap;

    constructor(ICLPoolManager _poolManager, uint24 _origFee, address _brevisRequest) CLBaseHook(_poolManager) BrevisApp(_brevisRequest) {
        origFee = _origFee;
    }

    // called by proxy to properly set storage of proxy contract
    function init(uint24 _origFee, address _brevisRequest, bytes32 _vkHash) external {
        initOwner(); // will fail if not called via delegateCall b/c owner is set in Ownable constructor
        // no need to emit event as it's first set in proxy state
        _setBrevisRequest(_brevisRequest);
        origFee = _origFee;
        vkmap[_vkHash] = true;
    }

    function getHooksRegistrationBitmap() external pure override returns (uint16) {
        return _hooksRegistrationBitmapFrom(
            Permissions({
                beforeInitialize: false,
                afterInitialize: false,
                beforeAddLiquidity: false,
                afterAddLiquidity: false,
                beforeRemoveLiquidity: false,
                afterRemoveLiquidity: false,
                beforeSwap: true, // only beforeSwap
                afterSwap: false,
                beforeDonate: false,
                afterDonate: false,
                beforeSwapReturnsDelta: false,
                afterSwapReturnsDelta: false,
                afterAddLiquidityReturnsDelta: false,
                afterRemoveLiquidityReturnsDelta: false
            })
        );
    }

    function beforeSwap(address, PoolKey calldata key, ICLPoolManager.SwapParams calldata, bytes calldata)
        external
        override
        poolManagerOnly
        returns (bytes4, BeforeSwapDelta, uint24)
    {
        uint24 dynFee = getFee(tx.origin);
        emit TxOrigin(tx.origin);
        return (this.beforeSwap.selector, BeforeSwapDeltaLibrary.ZERO_DELTA, dynFee | LPFeeLibrary.OVERRIDE_FEE_FLAG);
    }

    // brevisApp interface
    function handleProofResult(bytes32 _vkHash, bytes calldata _appCircuitOutput) internal override {
        require(vkmap[_vkHash], "invalid vk");
        updateBatch(_appCircuitOutput);
    }

    function setFee(uint24 _newfee) external onlyOwner {
        origFee = _newfee;
        emit FeeUpdated(_newfee);
    }

    function addVkHash(bytes32 _vkh) external onlyOwner {
        vkmap[_vkh]=true;
        emit VkHashAdded(_vkh);        
    }

    function rmVkHash(bytes32 _vkh) external onlyOwner {
        delete vkmap[_vkh];
        emit VkHashRemoved(_vkh);
    }

    function setBrevisRequest(address _brevisRequest) external onlyOwner {
        _setBrevisRequest(_brevisRequest);
        emit BrevisReqUpdated(_brevisRequest);
    }
}
