// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {PoolKey} from "@pancakeswap/v4-core/src/types/PoolKey.sol";
import {BalanceDelta} from "@pancakeswap/v4-core/src/types/BalanceDelta.sol";
import {PoolId, PoolIdLibrary} from "@pancakeswap/v4-core/src/types/PoolId.sol";
import {IBinPoolManager} from "@pancakeswap/v4-core/src/pool-bin/interfaces/IBinPoolManager.sol";
import {SwapFeeLibrary} from "@pancakeswap/v4-core/src/libraries/SwapFeeLibrary.sol";
import {BinBaseHook} from "./BinBaseHook.sol";
import {VipDiscountMap} from "../VipDiscountMap.sol";

// TODO: integrate Brevis callback

/// @notice BinVipHook is a contract that provides fee discount based on VIP tiers
contract BinVipHook is BinBaseHook, VipDiscountMap {
    using PoolIdLibrary for PoolKey;

    constructor(IBinPoolManager _poolManager) BinBaseHook(_poolManager) {}

    function getHooksRegistrationBitmap() external pure override returns (uint16) {
        return _hooksRegistrationBitmapFrom(
            Permissions({
                beforeInitialize: false,
                afterInitialize: false,
                beforeMint: false,
                afterMint: false,
                beforeBurn: false,
                afterBurn: false,
                beforeSwap: true,
                afterSwap: false,
                beforeDonate: false,
                afterDonate: false,
                noOp: false
            })
        );
    }

    function beforeSwap(address, PoolKey calldata key, bool, uint128, bytes calldata)
        external
        override
        poolManagerOnly
        returns (bytes4)
    {
        uint24 dynFee = getFee(tx.origin, key.fee);
        if (dynFee != key.fee) {
            poolManager.updateDynamicSwapFee(key, dynFee);
        }
        // emit tx.origin & poolid
        return this.beforeSwap.selector;
    }
}
