// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2;

contract MergeSortedArray {
    function merge(uint256[] memory _arr1, uint256[] memory _arr2) public pure returns (uint256[] memory) {
        uint256 length1 = _arr1.length;
        uint256 length2 = _arr2.length;
        uint256[] memory result = new uint256[](length1 + length2);
        uint256 i = 0;
        uint256 j = 0;
        uint256 k = 0;

        while (i < length1 && j < length2) {
            if (_arr1[i] < _arr2[j]) {
                result[k] = _arr1[i];
                ++i;
            } else {
                result[k] = _arr2[j];
                ++j;
            }
            ++k;
        }

        while (i < length1) {
            result[k] = _arr1[i];
            ++i;
            ++k;
        }

        while (j < length2) {
            result[k] = _arr2[j];
            ++j;
            ++k;
        }

        return result;
    }
}