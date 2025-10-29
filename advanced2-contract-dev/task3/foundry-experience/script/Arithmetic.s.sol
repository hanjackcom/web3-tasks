// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {Arithmetic} from "../src/Arithmetic.sol";

contract ArithmeticScript is Script {
    Arithmetic public arithmetic;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        arithmetic = new Arithmetic();

        console.log("Arithmetic deployed at:", address(arithmetic));

        uint256 addResult = arithmetic.add(10, 5);
        console.log("10+5=", addResult);

        uint256 subtractResult = arithmetic.subtract(20, 8);
        console.log("20-8=", subtractResult);

        uint256 multiplyResult = arithmetic.multiply(6, 7);
        console.log("6*7=", multiplyResult);

        uint256 divideResult = arithmetic.divide(20, 4);
        console.log("20/4=", divideResult);

        console.log("Total operations:", arithmetic.getOperationCount());
        console.log("Last result:", arithmetic.lastResult());

        vm.stopBroadcast();
    }
}
