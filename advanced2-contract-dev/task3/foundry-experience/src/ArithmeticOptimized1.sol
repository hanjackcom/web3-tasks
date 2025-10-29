// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract ArithmeticOptimized1 {
    uint256 public lastResult;

    event ResultUpdated(uint256 newResult);

    function add(uint256 a, uint256 b) public returns (uint256 result) {
        result = a + b;
        lastResult = result;
        emit ResultUpdated(result);
        return result;
    }

    function subtract(uint256 a, uint256 b) public returns (uint256 result) {
        require(a >= b, "Subtraction would result in negative number");
        result = a - b;
        lastResult = result;
        emit ResultUpdated(result);
        return result;
    }

    function multiply(uint256 a, uint256 b) public returns (uint256 result) {
        result = a * b;
        lastResult = result;
        emit ResultUpdated(result);
        return result;
    }

    function divide(uint256 a, uint256 b) public returns (uint256 result) {
        require(b != 0, "Division by zero");
        result = a / b;
        lastResult = result;
        emit ResultUpdated(result);
        return result;
    }

    function resetLastResult() public {
        lastResult = 0;
        emit ResultUpdated(0);
    }

    function batchCalculate(uint8[] calldata operations, uint256[] calldata operands1, uint256[] calldata operands2)
        external
        returns (uint256[] memory results)
    {
        require(
            operations.length == operands1.length && operands1.length == operands2.length, "Array length must match"
        );

        results = new uint256[](operations.length);
        uint256 tempResult;

        for (uint256 i = 0; i < operations.length;) {
            uint256 a = operands1[i];
            uint256 b = operands2[i];

            if (operations[i] == 0) {
                tempResult = a + b;
            } else if (operations[i] == 1) {
                require(a >= b, "Subtraction would result in negative number");
                tempResult = a - b;
            } else if (operations[i] == 2) {
                tempResult = a * b;
            } else if (operations[i] == 3) {
                require(b != 0, "Divison by zero");
                tempResult = a / b;
            } else {
                revert("Invalid operation");
            }

            results[i] = tempResult;

            unchecked {
                ++i;
            }
        }

        // only update last result
        if (results.length > 0) {
            lastResult = results[results.length - 1];
            emit ResultUpdated(lastResult);
        }

        return results;
    }
}
