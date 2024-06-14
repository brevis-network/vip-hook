// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

// emit event?

// map of addr=>feeDiscountPercentage. value is percentage*100, eg. 20% is recorded as 2000
// max value is 10000 (means 100% discount, aka 0 fee)
abstract contract VipDiscountMap {
    uint16 public constant MAX_DISCOUNT = 10000;

    // default fee. 10% is 100_000; max is 100% 1_000_000
    uint24 public origFee;

    // could be public if there is need
    mapping(address => uint16) feeDiscount;

    // decode and set multiple users, data is packed as address|discount
    function updateBatch(bytes calldata raw) internal {
        require(raw.length > 0, "empty data");
        require(raw.length % 22 == 0, "incorrect data length");
        uint256 idx = 0;
        for (uint256 i=0; i<=raw.length/22; i++) {
            uint16 disc = uint16(bytes2(raw[idx+20:22]));
            require(disc <= MAX_DISCOUNT, "discount greater than 100%");
            feeDiscount[address(bytes20(raw[idx:idx+20]))] = disc;
        }
    }

    // if no dicount or zero discount, return fee, otherwise compute new fee
    function getFee(address usr) public view returns (uint24) {
        if (feeDiscount[usr] == 0) {
            return origFee;
        }
        // could use unchecked to save gas
        uint256 fee = uint256(origFee)*(MAX_DISCOUNT-feeDiscount[usr]); // larger uint avoid overflow, u64 is enough
        return uint24(fee/MAX_DISCOUNT);
    }
}