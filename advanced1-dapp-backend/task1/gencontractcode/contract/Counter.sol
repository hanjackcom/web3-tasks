// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Counter {
    uint256 private count;

    event IncrementCounter(uint256 resCount);
    event DecrementCounter(uint256 resCount);

    constructor() {
        count = 0;
    }

    function increment() public {
        count += 1;
        emit IncrementCounter(count);
    }

    function decrement() public {
        require(count > 0, "Count cannot be negative");
        count -= 1;
        emit DecrementCounter(count);
    }

    function getCount() public view returns (uint256) {
        return count;
    }
}
