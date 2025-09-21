// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2;

contract Int2Roman {
    function intToRoman(uint256 _num) public pure returns (string memory) {
        require(_num >= 1 && _num <= 3999, "Number must be between 1 and 3999.");
        uint256[] memory values = new uint256[](13);
        string[] memory symbols = new string[](13);
        values[0] = 1000; symbols[0] = "M";
        values[1] = 900; symbols[1] = "CM";
        values[2] = 500; symbols[2] = "D";
        values[3] = 400; symbols[3] = "CD";
        values[4] = 100; symbols[4] = "C";
        values[5] = 90; symbols[5] = "XC";
        values[6] = 50; symbols[6] = "L";
        values[7] = 40; symbols[7] = "XL";
        values[8] = 10; symbols[8] = "X";
        values[9] = 9; symbols[9] = "IX";
        values[10] = 5; symbols[10] = "V";
        values[11] = 4; symbols[11] = "IV";
        values[12] = 1; symbols[12] = "I";

        bytes memory result = new bytes(0);
        for (uint256 i = 0; i < 13; ++i) {
            while (_num >= values[i]) {
                result = abi.encodePacked(result, symbols[i]);
                _num -= values[i];
            }
            if (_num == 0) break;
        }

        return string(result);
    }
}