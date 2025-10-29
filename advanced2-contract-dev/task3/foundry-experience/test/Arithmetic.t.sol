// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {Arithmetic} from "../src/Arithmetic.sol";

contract ArithmeticTest is Test {
    Arithmetic public arithmetic;

    struct GasRecord {
        string operation;
        uint256 gasUsed;
        uint256 operand1;
        uint256 operand2;
        uint256 result;
    }

    GasRecord[] public gasRecords;

    function setUp() public {
        arithmetic = new Arithmetic();
    }

    function test_Add() public {
        uint256 gasBefore = gasleft();
        uint256 result = arithmetic.add(10, 5);
        uint256 gasAfter = gasleft();
        uint256 gasUsed = gasBefore - gasAfter;

        gasRecords.push(GasRecord({operation: "add", gasUsed: gasUsed, operand1: 10, operand2: 5, result: result}));

        assertEq(result, 15);
        assertEq(arithmetic.lastResult(), 15);
        assertEq(arithmetic.getOperationCount(), 1);

        console.log("Add operation gas used:", gasUsed);
    }

    function test_Subtract() public {
        uint256 gasBefore = gasleft();
        uint256 result = arithmetic.subtract(20, 8);
        uint256 gasAfter = gasleft();
        uint256 gasUsed = gasBefore - gasAfter;

        gasRecords.push(GasRecord({operation: "subtract", gasUsed: gasUsed, operand1: 20, operand2: 8, result: result}));

        assertEq(result, 12);
        assertEq(arithmetic.lastResult(), 12);

        console.log("Subtract operation gas used:", gasUsed);
    }

    function test_SubtractRevert() public {
        vm.expectRevert("Subtraction would reuslt in nagative number"); // NOTE:: reuslt, not result
        arithmetic.subtract(5, 10);
    }

    function test_Multiply() public {
        uint256 gasBefore = gasleft();
        uint256 result = arithmetic.multiply(6, 7);
        uint256 gasAfter = gasleft();
        uint256 gasUsed = gasBefore - gasAfter;

        gasRecords.push(GasRecord({operation: "multiply", gasUsed: gasUsed, operand1: 6, operand2: 7, result: result}));

        assertEq(result, 42);
        assertEq(arithmetic.lastResult(), 42);

        console.log("Multiply operation gas used:", gasUsed);
    }

    function test_Divide() public {
        uint256 gasBefore = gasleft();
        uint256 result = arithmetic.divide(20, 4);
        uint256 gasAfter = gasleft();
        uint256 gasUsed = gasBefore - gasAfter;

        gasRecords.push(GasRecord({operation: "divide", gasUsed: gasUsed, operand1: 20, operand2: 4, result: result}));

        assertEq(result, 5);
        assertEq(arithmetic.lastResult(), 5);

        console.log("Divide operation gas used:", gasUsed);
    }

    function test_DivideByZeroRevert() public {
        vm.expectRevert("Division by zero");
        arithmetic.divide(10, 0);
    }

    function test_OperationHistory() public {
        arithmetic.add(1, 2);
        arithmetic.subtract(10, 3);
        arithmetic.multiply(4, 5);

        assertEq(arithmetic.getOperationCount(), 3);

        Arithmetic.Operation memory op1 = arithmetic.getOperation(0);
        assertEq(op1.operand1, 1);
        assertEq(op1.operand2, 2);
        assertEq(op1.result, 3);
        assertEq(op1.operation, "add");

        Arithmetic.Operation memory op2 = arithmetic.getOperation(1);
        assertEq(op2.operand1, 10);
        assertEq(op2.operand2, 3);
        assertEq(op2.result, 7);
        assertEq(op2.operation, "subtract");
    }

    function test_ResetLastResult() public {
        arithmetic.add(10, 5);
        assertEq(arithmetic.lastResult(), 15);

        arithmetic.resetLastResult();
        assertEq(arithmetic.lastResult(), 0);
    }

    function test_Events() public {
        vm.expectEmit(true, true, true, true);
        emit Arithmetic.OperationPerformed(10, 5, 15, "add");

        vm.expectEmit(true, true, true, true);
        emit Arithmetic.ResultUpdated(15);

        arithmetic.add(10, 5);
    }

    function test_GasConsumption() public {
        console.log("=== Gas Consumption Analysis ===");

        uint256[] memory addGasCosts = new uint256[](5);

        for (uint256 i = 0; i < 5; i++) {
            uint256 gasBefore = gasleft();
            arithmetic.add(i + 1, i + 2);
            uint256 gasAfter = gasleft();
            addGasCosts[i] = gasBefore - gasAfter;
            console.log("Add operation", i + 1, "gas used:", addGasCosts[i]);
        }

        console.log("First add gas:", addGasCosts[0]);
        console.log("Last add gas:", addGasCosts[4]);

        if (addGasCosts[4] >= addGasCosts[0]) {
            console.log("Gas increase per operation:", addGasCosts[4] - addGasCosts[0]);
        } else {
            console.log("Gas decrease per operation:", addGasCosts[0] - addGasCosts[4]);
        }
    }

    function testFuzz_Add(uint128 a, uint128 b) public {
        // using uint128, in case avoiding overflow
        uint256 result = arithmetic.add(a, b);
        assertEq(result, uint256(a) + uint256(b));
        assertEq(arithmetic.lastResult(), result);
    }

    function testFuzz_Subtract(uint256 a, uint256 b) public {
        vm.assume(a >= b); // ensure that result is not negative

        uint256 result = arithmetic.subtract(a, b);
        assertEq(result, a - b);
        assertEq(arithmetic.lastResult(), result);
    }

    function testFuzz_Multiply(uint128 a, uint128 b) public {
        uint256 result = arithmetic.multiply(a, b);
        assertEq(result, uint256(a) * uint256(b));
        assertEq(arithmetic.lastResult(), result);
    }

    function testFuzz_Divide(uint256 a, uint256 b) public {
        vm.assume(b != 0);

        uint256 result = arithmetic.divide(a, b);
        assertEq(result, a / b);
        assertEq(arithmetic.lastResult(), result);
    }
}
