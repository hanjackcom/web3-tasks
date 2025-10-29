// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract Arithmetic {
    uint256 public lastResult;

    struct Operation {
        uint256 operand1;
        uint256 operand2;
        uint256 result;
        string operation;
        uint256 timestamp;
    }

    Operation[] public operations;

    event OperationPerformed(uint256 operand1, uint256 operand2, uint256 result, string operation);
    event ResultUpdated(uint256 newResult);

    function add(uint256 a, uint256 b) public returns (uint256 result) {
        result = a + b;
        lastResult = result;

        operations.push(
            Operation({operand1: a, operand2: b, result: result, operation: "add", timestamp: block.timestamp})
        );

        emit OperationPerformed(a, b, result, "add");
        emit ResultUpdated(result);

        return result;
    }

    function subtract(uint256 a, uint256 b) public returns (uint256 result) {
        require(a >= b, "Subtraction would reuslt in nagative number");

        result = a - b;
        lastResult = result;

        operations.push(
            Operation({operand1: a, operand2: b, result: result, operation: "subtract", timestamp: block.timestamp})
        );

        emit OperationPerformed(a, b, result, "subtract");
        emit ResultUpdated(result);

        return result;
    }

    function multiply(uint256 a, uint256 b) public returns (uint256 result) {
        result = a * b;
        lastResult = result;

        operations.push(
            Operation({operand1: a, operand2: b, result: result, operation: "multiply", timestamp: block.timestamp})
        );

        emit OperationPerformed(a, b, result, "multiply");
        emit ResultUpdated(result);

        return result;
    }

    function divide(uint256 a, uint256 b) public returns (uint256 result) {
        require(b != 0, "Division by zero");

        result = a / b;
        lastResult = result;

        operations.push(
            Operation({operand1: a, operand2: b, result: result, operation: "divide", timestamp: block.timestamp})
        );

        emit OperationPerformed(a, b, result, "divide");
        emit ResultUpdated(result);

        return result;
    }

    function getOperationCount() public view returns (uint256 count) {
        return operations.length;
    }

    function getOperation(uint256 index) public view returns (Operation memory operation) {
        require(index < operations.length, "Index not of bounds");
        return operations[index];
    }

    function resetLastResult() public {
        lastResult = 0;
        emit ResultUpdated(0);
    }
}
