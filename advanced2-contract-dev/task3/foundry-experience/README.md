## Foundry智能合约Gas优化

本项目使用Foundry框架完成智能合约开发、测试和Gas优化分析的完整流程。

## 工程结构

```shell
foundry-experience
|-- README.md
|-- foundry.lock
|-- foundry.toml
|-- lib
|   `-- forge-std
|-- script
|   `-- Arithmetic.s.sol # deploy script
|-- src
|   |-- Arithmetic.sol # original arithmetic contract
|   |-- ArithmeticOptimized1.sol # gas optimized1
|   `-- ArithmeticOptimized2.sol # gas optimized2
`-- test
    |-- Arithmetic.t.sol # original contract test
    `-- GasComparison.t.sol # comparison tes
```

## Quick Start

### 1.项目搭建

```shell
# install tools
curl -L https://foundry.paradigm.xyz | bash
source /root/.bashrc
foundryup --branch master

# init a project
forge init foundry-experience
cd foundry-experience

# fix your code

# format code
forge fmt
```

### 2.构建

```shell
# build & test contract
forge build
# or:
forge build -v # compile for details
```

### 3.测试
```shell
forge test
forge test --fork-url https://reth-ethereum.ithaca.xyz/rpc

forge test -vv # for details

forge test --gas-report # for gas report

forge test --match-contract ArithmeticTest # for special contract
forge test --match-contract GasComparisonTest

forge snapshot # snapshot test

```

### 3.部署

```shell
# deploy contract
# deloy in localhost
# another terminal launch anvil
anvil
# or:
# Fork latest mainnet state for testing
anvil --fork-url https://reth-ethereum.ithaca.xyz/rpc

# go back to old terminal, go on:
export PRIVATE_KEY="0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"
forge script script/Counter.s.sol --rpc-url http://127.0.0.1:8545 --broadcast --private-key $PRIVATE_KEY

```

### 4.交互操作

```shell
# terminal 1:
anvil --fork-url https://reth-ethereum.ithaca.xyz/rpc

# etminal 2:
# check eth balance:
cast balance vitalik.eth --ether --rpc-url https://reth-ethereum.ithaca.xyz/rpc
# call a contract function to read data:
cast call 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2 "balanceOf(address)" 0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045 --rpc-url https://reth-ethereum.ithaca.xyz/rpc

# set a private key 
export PRIVATE_KEY="0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"
# send eth to an address
cast send 0x70997970C51812dc3A010C7d01b50e0d17dc79C8 --value 10000000 --private-key $PRIVATE_KEY

# call json-rpc methods directly
cast rpc eth_getHeaderByNumber $(cast 2h 22539851) --rpc-url https://reth-ethereum.ithaca.xyz/rpc
# get latest block number:
cast block-number --rpc-url https://reth-ethereum.ithaca.xyz/rpc
# get lastest block
cast block # get block info in default net, ignore --rpc-url

# start a REPL:
chisel
# in console, your can input:
# create and query var:
# uint256 a = 123;
# a
# test a contract function:
# function add(uint256 x, uint256 y) public pure returns (uint256) {return x+y;}
# add(5, 10)
# !quit

```

## 合约功能说明

### Arithmetic (原始版本)
- 基本算术运算：加、减、乘、除
- 结果存储和历史记录
- 事件发射和查询功能
- 完整的状态管理

### ArithmeticOptimized1 (优化版本1)
- 移除操作历史存储
- 简化事件发射
- 新增批量计算功能
- 约73%的Gas节省

### ArithmeticOptimized2 (优化版本2)
- 极简设计，移除所有非必要功能
- 使用assembly优化
- 纯函数设计
- 最高97%的Gas节省

## Gas优化成果

| 操作类型 | 原始合约 | 优化版本1 | 优化版本2 | 节省率1 | 节省率2 |
|---------|---------|----------|----------|---------|----------|
| 单次运算 | ~187k gas | ~51k gas | ~50k gas | 72.8% | 73.5% |
| 批量运算 | ~635k gas | ~66k gas | ~14k gas | 89.6% | 97.8% |

## 测试覆盖

- ✅ 功能测试：验证算术运算正确性
- ✅ 边界测试：处理溢出、除零等情况
- ✅ Gas分析：详细的Gas消耗记录
- ✅ 模糊测试：随机输入验证
- ✅ 性能对比：系统性的优化效果分析

## 主要文件说明

- **GAS_OPTIMIZATION_REPORT.md**: 详细的Gas优化分析报告
- **test/GasComparison.t.sol**: 三个版本合约的性能对比测试
- **src/**: 包含三个不同优化程度的智能合约

## 技术栈

- **Foundry**: 智能合约开发框架
- **Solidity**: 智能合约编程语言 (^0.8.13)
- **Forge**: 测试和构建工具
- **Cast**: 以太坊交互工具

## 学习价值

本项目展示了：
1. Foundry框架的完整使用流程
2. 系统性的Gas优化策略
3. 完整的测试驱动开发流程
4. 性能分析和对比方法
5. 智能合约最佳实践

### 参考文档

> https://github.com/liuquan0807/solidityWork02/blob/main/foundry/src/Counter.sol
> https://getfoundry.sh/introduction/getting-started
> https://book.getfoundry.sh/


