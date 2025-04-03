// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

// emit event?

// map of addr=>feeDiscountPercentage. value is percentage*100, eg. 20% is recorded as 2000
// max value is 10000 (means 100% discount, aka 0 fee)
abstract contract VipDiscountMap {
    event FeeDiscountUpdated(address indexed usr, uint16 indexed discount);
    uint16 public constant MAX_DISCOUNT = 10000;

    // default fee. 10% is 100_000; max is 100% 1_000_000
    uint24 public origFee;
    uint32 public epoch;

    // could be public if there is need
    mapping(address => uint16) feeDiscount;

    // decode and set multiple users, data is packed as epoch| [address|discount]
    function updateBatch(bytes calldata raw) internal {
        require(raw.length > 0, "empty data");
        require((raw.length-4) % 22 == 0, "incorrect data length");
        uint32 epo = uint32(bytes4(raw[0:4]));
        require(epo >= epoch, "old epoch");
        if (epo > epoch) {
            epoch = epo;
        }
        for (uint256 idx=4; idx<raw.length; idx+=22) {
            address usr = address(bytes20(raw[idx:idx+20]));
            // due to fixed circuit output, we may have 0 addr for padding. break to save gas
            if (usr == address(0)) {
                break;
            }

            uint16 disc = uint16(bytes2(raw[idx+20:idx+22]));
            require(disc <= MAX_DISCOUNT, "discount greater than 100%");

            feeDiscount[usr] = disc;
            emit FeeDiscountUpdated(usr, disc);
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