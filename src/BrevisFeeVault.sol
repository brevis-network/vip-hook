// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./Ownable.sol";

// deposit by pool deployers and owner can withdraw
contract BrevisFee is Ownable {
    event Funded(bytes32 indexed poolId, uint256 value);
    event Collected(bytes32 indexed poolId, uint256 value, address receiver);

    // per poolId (bytes32 type) prepaid fee
    mapping(bytes32 => uint256) public balance;

    function fund(bytes32 poolId) external payable {
        // use unchecked could save some gas
        balance[poolId] += msg.value;
        emit Funded(poolId, msg.value);
    }

    function collect(address payable receiver, bytes32 poolId, uint256 value) external onlyOwner {
        require(balance[poolId] >= value, "insufficient balance");
        // unchecked could save gas
        balance[poolId] -= value;
        (bool success,) = receiver.call{value: value}("");
        require(success, "Failed to send Ether");
        emit Collected(poolId, value, receiver);
    }

    // collect all fees in list of pools
    function collectAll(address payable receiver, bytes32[] calldata poolIds) external onlyOwner {
        for (uint256 i=0; i<=poolIds.length; i++) {
            if (balance[poolIds[i]] > 0) {
                uint256 val = balance[poolIds[i]];
                balance[poolIds[i]] = 0;
                (bool success,) = receiver.call{value: val}("");
                require(success, "Failed to send Ether");
                emit Collected(poolIds[i], val, receiver);
            }
        }
    }
}