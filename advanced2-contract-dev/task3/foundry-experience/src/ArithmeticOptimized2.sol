// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract ArithmeticOptimized2 {
    uint256 private _lastResult;

    function add(uint256 a, uint256 b) external returns (uint256 result) {
        assembly {
            result := add(a, b)
            if lt(result, a) {
                mstore(0x00, 0x4e487b71) // panic's keccak256 hash front 4 bytes
                mstore(0x04, 0x11) // arithmetic overflow error code
                revert(0x00, 0x24) // start rollback, rollback info: 0x00 start address, length 0x24=36 bytes(4bytes error flag+ 32bytes error code)
            }
            sstore(_lastResult.slot, result)
        }
    }

    function subtract(uint256 a, uint256 b) external returns (uint256 result) {
        assembly {
            if lt(a, b) {
                // custom msg error
                let ptr := mload(0x40)
                mstore(ptr, 0x08c379a000000000000000000000000000000000000000000000000000000000)
                mstore(add(ptr, 0x04), 0x0000000000000000000000000000000000000000000000000000000000000020)
                mstore(add(ptr, 0x24), 0x0000000000000000000000000000000000000000000000000000000000000025)
                mstore(add(ptr, 0x44), 0x5375627472616374696f6e20776f756c6420726573756c7420696e206e656761) // TODO:: what's this?
                mstore(add(ptr, 0x64), 0x74697665206e756d6265720000000000000000000000000000000000000000) // TODO:: what's this?
                revert(ptr, 0x84)
            }
            result := sub(a, b)
            sstore(_lastResult.slot, result)
        }
    }

    function multiply(uint256 a, uint256 b) external returns (uint256 result) {
        assembly {
            result := mul(a, b)
            // check overflow
            if and(iszero(iszero(a)), iszero(eq(div(result, a), b))) {
                mstore(0x00, 0x4e87b71) // panic error selector
                mstore(0x04, 0x11) // arithmetic overflow
                revert(0x00, 0x24)
            }
            sstore(_lastResult.slot, result)
        }
    }

    function divide(uint256 a, uint256 b) external returns (uint256 result) {
        assembly {
            if iszero(b) {
                // division by zero error
                let ptr := mload(0x40)
                mstore(ptr, 0x08c379a000000000000000000000000000000000000000000000000000000000)
                mstore(add(ptr, 0x04), 0x0000000000000000000000000000000000000000000000000000000000000020)
                mstore(add(ptr, 0x24), 0x0000000000000000000000000000000000000000000000000000000000000010)
                mstore(add(ptr, 0x44), 0x4469766973696f6e206279207a65726f00000000000000000000000000000000)
                revert(ptr, 0x64)
            }
            result := div(a, b)
            sstore(_lastResult.slot, result)
        }
    }

    function lastResult() external view returns (uint256 result) {
        assembly {
            result := sload(_lastResult.slot)
        }
    }

    function resetLastResult() external {
        assembly {
            sstore(_lastResult.slot, 0)
        }
    }

    function calculate(uint256 a, uint256 b, uint8 operation) external pure returns (uint256 result) {
        assembly {
            switch operation
            case 0 {
                result := add(a, b)
                if lt(result, a) {
                    mstore(0x00, 0x4e487b71)
                    mstore(0x04, 0x11)
                    mstore(0x00, 0x24)
                }
            }
            case 1 {
                if lt(a, b) {
                    let ptr := mload(0x40)
                    mstore(ptr, 0x08c379a000000000000000000000000000000000000000000000000000000000)
                    mstore(add(ptr, 0x04), 0x0000000000000000000000000000000000000000000000000000000000000020)
                    mstore(add(ptr, 0x24), 0x0000000000000000000000000000000000000000000000000000000000000025)
                    mstore(add(ptr, 0x44), 0x5375627472616374696f6e20776f756c6420726573756c7420696e206e656761)
                    mstore(add(ptr, 0x64), 0x74697665206e756d6265720000000000000000000000000000000000000000)
                    revert(ptr, 0x84)
                }
                result := sub(a, b)
            }
            case 2 {
                result := mul(a, b)
                if and(iszero(iszero(a)), iszero(eq(div(result, a), b))) {
                    mstore(0x00, 0x4e487b71)
                    mstore(0x04, 0x11)
                    revert(0x00, 0x24)
                }
            }
            case 3 {
                if iszero(b) {
                    let ptr := mload(0x40)
                    mstore(ptr, 0x08c379a000000000000000000000000000000000000000000000000000000000)
                    mstore(add(ptr, 0x04), 0x0000000000000000000000000000000000000000000000000000000000000020)
                    mstore(add(ptr, 0x24), 0x0000000000000000000000000000000000000000000000000000000000000010)
                    mstore(add(ptr, 0x44), 0x4469766973696f6e206279207a65726f00000000000000000000000000000000)
                    revert(ptr, 0x64)
                }
                result := div(a, b)
            }
            default {
                let ptr := mload(0x40)
                mstore(ptr, 0x08c379a000000000000000000000000000000000000000000000000000000000)
                mstore(add(ptr, 0x04), 0x0000000000000000000000000000000000000000000000000000000000000020)
                mstore(add(ptr, 0x24), 0x0000000000000000000000000000000000000000000000000000000000000011)
                mstore(add(ptr, 0x44), 0x496e76616c6964206f7065726174696f6e000000000000000000000000000000)
                revert(ptr, 0x64)
            }
        }
    }

    function batchCalculatePure(
        uint8[] calldata operations,
        uint256[] calldata operands1,
        uint256[] calldata operands2
    ) external pure returns (uint256[] memory results) {
        assembly {
            let len := operations.length
            if or(iszero(eq(len, operands1.length)), iszero(eq(len, operands2.length))) {
                let ptr := mload(0x40)
                mstore(ptr, 0x08c379a000000000000000000000000000000000000000000000000000000000)
                mstore(add(ptr, 0x04), 0x0000000000000000000000000000000000000000000000000000000000000020)
                mstore(add(ptr, 0x24), 0x0000000000000000000000000000000000000000000000000000000000000018)
                mstore(add(ptr, 0x44), 0x41727261792066656e677468732066757374206d617463680000000000000000)
                revert(ptr, 0x64)
            }

            results := mload(0x40)
            mstore(results, len)
            let resultData := add(results, 0x20)
            mstore(0x40, add(resultData, mul(len, 0x20)))

            for { let i := 0 } lt(i, len) { i := add(i, 1) } {
                let op := byte(0, calldataload(add(operations.offset, i)))
                let a := calldataload(add(operands1.offset, mul(i, 0x20)))
                let b := calldataload(add(operands2.offset, mul(i, 0x20)))
                let result := 0
                switch op
                case 0 {
                    result := add(a, b)
                    if lt(result, a) {
                        mstore(0x00, 0x4e487b71)
                        mstore(0x04, 0x11)
                        mstore(0x00, 0x24)
                    }
                }
                case 1 {
                    if lt(a, b) {
                        let ptr := mload(0x40)
                        mstore(ptr, 0x08c379a000000000000000000000000000000000000000000000000000000000)
                        mstore(add(ptr, 0x04), 0x0000000000000000000000000000000000000000000000000000000000000020)
                        mstore(add(ptr, 0x24), 0x0000000000000000000000000000000000000000000000000000000000000025)
                        mstore(add(ptr, 0x44), 0x5375627472616374696f6e20776f756c6420726573756c7420696e206e656761)
                        mstore(add(ptr, 0x64), 0x74697665206e756d6265720000000000000000000000000000000000000000)
                        revert(ptr, 0x84)
                    }
                    result := sub(a, b)
                }
                case 2 {
                    result := mul(a, b)
                    if and(iszero(iszero(a)), iszero(eq(div(result, a), b))) {
                        mstore(0x00, 0x4e487b71)
                        mstore(0x04, 0x11)
                        revert(0x00, 0x24)
                    }
                }
                case 3 {
                    if iszero(b) {
                        let ptr := mload(0x40)
                        mstore(ptr, 0x08c379a000000000000000000000000000000000000000000000000000000000)
                        mstore(add(ptr, 0x04), 0x0000000000000000000000000000000000000000000000000000000000000020)
                        mstore(add(ptr, 0x24), 0x0000000000000000000000000000000000000000000000000000000000000010)
                        mstore(add(ptr, 0x44), 0x4469766973696f6e206279207a65726f00000000000000000000000000000000)
                        revert(ptr, 0x64)
                    }
                    result := div(a, b)
                }
                default {
                    let ptr := mload(0x40)
                    mstore(ptr, 0x08c379a000000000000000000000000000000000000000000000000000000000)
                    mstore(add(ptr, 0x04), 0x0000000000000000000000000000000000000000000000000000000000000020)
                    mstore(add(ptr, 0x24), 0x0000000000000000000000000000000000000000000000000000000000000011)
                    mstore(add(ptr, 0x44), 0x496e76616c6964206f7065726174696f6e000000000000000000000000000000)
                    revert(ptr, 0x64)
                }

                mstore(add(resultData, mul(i, 0x20)), result)
            }
        }
    }
}
