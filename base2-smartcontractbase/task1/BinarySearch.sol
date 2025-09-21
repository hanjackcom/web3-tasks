// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2;

contract BinarySearch {
    function binarySearch(uint256[] memory _sortedArr, uint256 _target) private pure returns (uint256) {
        uint256 left = 0;
        uint256 right = _sortedArr.length - 1;
        
        while(left <= right) {
            uint256 middle = left + (right - left) / 2;
            uint256 middleValue = _sortedArr[middle];
            if (middleValue == _target) {
                return middle;
            } else if (middleValue < _target) {
                left = middle + 1;
            } else {
                right = middle - 1;
            }
        }

        return type(uint256).max;
    }

    function searchResult(uint256[] memory _sortedArr, uint256 _target) public pure returns (bool found, uint256 index) {
        uint256 result = binarySearch(_sortedArr, _target);
        if (result == type(uint256).max) {
            return (false, 0);
        }
        return (true, result);
    }
}