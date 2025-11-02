# MetaNodeStake Project （质押合约项目）

基于Openzeppelin的可升级质押智能合约项目，支持ETH和ERC20代币质押。

### 功能

#### 特性描述

* 多资产质押：支持ETH和ERC20代币质押
* 灵活奖励：基于区块的奖励分发机制
* 权限管理：基于角色的访问控制
* 可升级：使用UUPS代理模式进行合约升级
* 安全提取：防挤兑的延迟提取机制

#### 主要功能接口

* depositETH() - ETH质押
* deposit(pid, amount) - ERC20代币质押
* unstake(pid, amount) - 发起解质押请求
* withdraw(pid) - 提取已解锁资产
* claim(pid) - 领取奖励
* addPool() - 添加质押池（管理员）

### 合约架构

#### 主要合约

* MetaNodeToken.sol - 代币合约，用于奖励
* MetaNodeStake.sol - 质押合约

#### 项目框架

```shell
tree metanode-stake -L 3 -I "node_modules|artifacts|cache"
metanode-stake
|-- README.md
|-- contracts
|   |-- MetaNodeStake.sol
|   `-- MetaNodeToken.sol
|-- hardhat.config.js
|-- ignition
|   |-- deployments
|   |   `-- chain-31337
|   `-- modules
|       |-- MetaNodeStake.js
|       `-- MetaNodeToken.js
|-- package-lock.json
|-- package.json
`-- test
    `-- test.js
```


### 项目构建步骤

Project build steps:

```shell
mkdir metanode-stake && cd metanode-stake
npm init
npm install --save-dev hardhat
npm install --save-dev solidity-coverage
npm install --save-dev hardhat-gas-reporter
npx hardhat init

npm install --save-dev dotenv
npm install @openzeppelin/contracts
npm install @openzeppelin/contracts-upgradeable

# fix code and config file

npx hardhat help

npx hardhat node
npx hardhat ignition deploy ./ignition/modules/MetaNodeToken.js --network localhost
npx hardhat ignition deploy ./ignition/modules/MetaNodeStake.js --network localhost

npx hardhat deploy --network localhost

npx hardhat test
REPORT_GAS=true npx hardhat test

### use coverage
npx hardhat clean
npx hardhat compile
npx hardhat coverage

### 
# https://coinmarketcap.com/
npx hardhat test


```

