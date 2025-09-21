// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2;

contract Roman2Int {
    function getValue(bytes1 _c) private pure returns (uint256) {
        if (_c == "I") return 1;
        if (_c == "V") return 5;
        if (_c == "X") return 10;
        if (_c == "L") return 50;
        if (_c == "C") return 100;
        if (_c == "D") return 500;
        if (_c == "M") return 1000;

        revert("Invalid char in Roman numeral.");
    }

    function romanToInt(string memory _romanStr) public pure returns (uint256) {
        bytes memory romanBytes = bytes(_romanStr);
        uint256 length = romanBytes.length;
        require(length > 0 && length <= 15, "Roman Str length is be between 1 to 15 characteres");
        uint256 total = 0;
        for (uint256 i = 0; i < length; ++i) {
            uint256 value = getValue(romanBytes[i]);
            if (i < length - 1 && value < getValue(romanBytes[i + 1])) {
                total -= value;
            } else {
                total += value;
            }
        }

        require(total >= 1 && total <= 3999, "Invalid Roman numeral.");
        return total;
    }
}
