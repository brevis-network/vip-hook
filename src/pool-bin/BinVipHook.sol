// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {LPFeeLibrary} from "@pancakeswap/v4-core/src/libraries/LPFeeLibrary.sol";
import {PoolKey} from "@pancakeswap/v4-core/src/types/PoolKey.sol";
import {BalanceDelta} from "@pancakeswap/v4-core/src/types/BalanceDelta.sol";
import {BeforeSwapDelta, BeforeSwapDeltaLibrary} from "@pancakeswap/v4-core/src/types/BeforeSwapDelta.sol";
import {PoolId, PoolIdLibrary} from "@pancakeswap/v4-core/src/types/PoolId.sol";
import {IBinPoolManager} from "@pancakeswap/v4-core/src/pool-bin/interfaces/IBinPoolManager.sol";
import {BinBaseHook} from "./BinBaseHook.sol";
import {VipDiscountMap} from "../VipDiscountMap.sol";

// TODO: integrate Brevis callback

/// @notice BinVipHook is a contract that provides fee discount based on VIP tiers
contract BinVipHook is BinBaseHook, VipDiscountMap {
    using PoolIdLibrary for PoolKey;

    constructor(IBinPoolManager _poolManager, uint24 _origFee) BinBaseHook(_poolManager) {
        origFee = _origFee;
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
                beforeSwap: true,
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

    function beforeSwap(address, PoolKey calldata key, bool, uint128, bytes calldata)
        external
        override
        poolManagerOnly
        returns (bytes4, BeforeSwapDelta, uint24)
    {
        uint24 dynFee = getFee(tx.origin);
        // emit tx.origin & poolid
        return (this.beforeSwap.selector, BeforeSwapDeltaLibrary.ZERO_DELTA, dynFee | LPFeeLibrary.OVERRIDE_FEE_FLAG);
    }
}
