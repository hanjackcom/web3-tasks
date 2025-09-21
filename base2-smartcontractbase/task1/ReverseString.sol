// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2;

contract ReverseString {
    function reverse(string memory _str) public pure returns (string memory) {
        bytes memory strBytes = bytes(_str);
        uint256 length = strBytes.length;
        bytes memory reversedBytes = new bytes(length);
        for (uint256 i = 0; i < length; ++i) {
            reversedBytes[i] = strBytes[length - 1 - i];
        }

        return string(reversedBytes);
    }
}