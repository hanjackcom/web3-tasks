### meme theory

go to meme theory directory.

---

### meme experience

#### project introduce

This is a DeFi project based hardhat, it consists of Meme token contract which own tax machinism and DEX liquidity pool contract.

##### base function:

###### Meme Token (ERC20)

* basic ERC20 function. i.e. transfer, approve
* 5% tranfer tax machinism
* free tax address whilelist machinism
* transaction limit daily
* mint/burn

###### LiquidityPool (DEX)

* add/remove liquidity
* swap eth for token, or swap token for eth
* 0.3% commission on transaction
* AMM auto maker machinism

---

#### project structure

```shell
tree meme-experience -L 3 -I "node_modules|artifacts|cache"
meme-experience
|-- README.md
|-- contracts
|   |-- LiquidityPool.sol
|   `-- Meme.sol
|-- hardhat.config.js
|-- ignition
|   |-- deployments
|   |   |-- chain-11155111
|   |   `-- chain-31337
|   `-- modules
|       |-- LiquidityPool.js
|       `-- Meme.js
|-- package-lock.json
|-- package.json
`-- test
    `-- Meme.js

```

---

#### operate guide

```shell
# 1. create project
mkdir meme-experience && cd meme-experience
npm init
npm install --save-dev hardhat@v2
npm install --save-dev solidity-coverage
npm install --save-dev hardhat-gas-reporter
npx hardhat init

npm install @openzeppelin/contracts
npm install @uniswap/v2-periphery

# 2. fix your code, .env, hardhat.config.js for network enviroment.
npm install --save-dev dotenv
cp .env.sample .env

npx hardhat
npx hardhat compile
npx hardhat test

# 3. deploy localhost after start node, or deploy sepolia
npx hardhat node # this cmd will start a local node at http://0.0.0.0:8545 , u may use it or specify sepolia
# npx hardhat ignition deploy ./ignition/modules/Lock.js # default localhost
npx hardhat ignition deploy ./ignition/modules/Meme.js --network localhost
# npx hardhat ignition deploy ./ignition/modules/Meme.js --network sepolia

# then write Meme.js's meme deployed address into ./ignition/modules/LiquidityPool.js
npx hardhat ignition deploy ./ignition/modules/LiquidityPool.js --network localhost
# npx hardhat ignition deploy ./ignition/modules/LiquidityPool.js --network sepolia

# if u add deploy task in hardhat.config.js, u can deploy as follow:
npx hardhat deploy --network localhost
# npx hardhat deploy --network sepolia

# 4. test and get report
npx hardhat test
# or:
REPORT_GAS=true npx hardhat test

# references: https://v2.hardhat.org/hardhat-runner/docs/getting-started#overview

### use coverage
npx hardhat clean
npx hardhat compile
npx hardhat coverage

### 
# https://coinmarketcap.com/
npx hardhat test

```

### interact contract in console

u may interact contract in console after deployed:

```shell
npx hardhat console --network localhost
```

```javascript
// get contract instance
const meme = await ethers.getContractAt("Meme", "CONTRACT_ADDRESS");
const pool = await ethers.getContractAt("LiquidityPool", "CONTRACT_ADDRESS");

// opreate token
await meme.transfer("ADDRESS", ethers.parseUnits("100", 18));
await meme.approve("POOL_ADDRESS", ethers.parseUnits("1000", 18));

// opreate liquidity
await pool.addLiquidity(ethers.parseUnits("1000", 18), { value: ethers.parseEther("1") });
await pool.swapETHForToken({ value: ethers.parseEther("0.1") });

// exit console
.exit
```

for example :
```javascript
const meme = await ethers.getContractAt("Meme", "0x9fe46736679d2d9a65f0992f2272de9f3c7fa6e0");
const pool = await ethers.getContractAt("LiquidityPool", "0xcf7ed3acca5a467e9e704c703e8d87f634fb0fc9");

const from = "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266";
const to = "0x70997970C51812dc3A010C7d01b50e0d17dc79C8";
await meme.balanceOf(from);
await meme.balanceOf(to);
await meme.getTotalSupply();

await meme.transfer(to, 20000000);
await meme.approve("0xcf7ed3acca5a467e9e704c703e8d87f634fb0fc9", 10000000);

await pool.addLiquidity(10000000, { value: ethers.parseEther("1") });
await pool.swapETHForToken({ value: ethers.parseEther("0.1") });
```

localhost test report:

```shell
root@1e49dbc520c1:/home/ubuntu/web3-tasks/advanced2-contract-dev/task1/meme-experience# REPORT_GAS=true npx hardhat test
[dotenv@17.2.3] injecting env (2) from .env -- tip: ⚙️  write to custom object with { processEnv: myObject }


  Meme
    ✔ should get the balance of the contract
    ✔ should transfer tokens correctly
    ✔ Should approve and transferFrom tokens
    ✔ should allow owner to mint tokens
    ✔ should allow owner to burn tokens
    ✔ should manage excluded from fees addresses

  LiquidityPool
    ✔ should deploy with correct meme token address
    ✔ should add liquidity correctly
    ✔ should remove liquidity correctly
    ✔ should swap ETH for tokens correctly
    ✔ should swap tokens for ETH correctly
    ✔ should get swap price preview correctly


  12 passing (221ms)

····················································································································
|  Solidity and Network Configuration                                                                              │
·······························|·················|···············|·················|································
|  Solidity: 0.8.28            ·  Optim: false   ·  Runs: 200    ·  viaIR: false   ·     Block: 30,000,000 gas     │
·······························|·················|···············|·················|································
|  Methods                                                                                                         │
·······························|·················|···············|·················|················|···············
|  Contracts / Methods         ·  Min            ·  Max          ·  Avg            ·  # calls       ·  usd (avg)   │
·······························|·················|···············|·················|················|···············
|  LiquidityPool               ·                                                                                   │
·······························|·················|···············|·················|················|···············
|      addLiquidity            ·        253,718  ·      258,518  ·        255,638  ·             5  ·           -  │
·······························|·················|···············|·················|················|···············
|      removeLiquidity         ·              -  ·            -  ·        148,306  ·             1  ·           -  │
·······························|·················|···············|·················|················|···············
|      swapETHForToken         ·              -  ·            -  ·        148,342  ·             1  ·           -  │
·······························|·················|···············|·················|················|···············
|      swapTokenForETH         ·              -  ·            -  ·        149,652  ·             1  ·           -  │
·······························|·················|···············|·················|················|···············
|  Meme                        ·                                                                                   │
·······························|·················|···············|·················|················|···············
|      addExcludedFromFees     ·              -  ·            -  ·         46,583  ·             1  ·           -  │
·······························|·················|···············|·················|················|···············
|      approve                 ·         46,728  ·       46,740  ·         46,738  ·             7  ·           -  │
·······························|·················|···············|·················|················|···············
|      burn                    ·              -  ·            -  ·         36,726  ·             1  ·           -  │
·······························|·················|···············|·················|················|···············
|      mint                    ·              -  ·            -  ·         54,326  ·             1  ·           -  │
·······························|·················|···············|·················|················|···············
|      removeExcludedFromFees  ·              -  ·            -  ·         24,682  ·             1  ·           -  │
·······························|·················|···············|·················|················|···············
|      transfer                ·         73,708  ·      128,136  ·        100,922  ·             2  ·           -  │
·······························|·················|···············|·················|················|···············
|      transferFrom            ·              -  ·            -  ·        161,367  ·             1  ·           -  │
·······························|·················|···············|·················|················|···············
|  Deployments                                   ·                                 ·  % of limit    ·              │
·······························|·················|···············|·················|················|···············
|  LiquidityPool               ·      1,431,883  ·    1,431,895  ·      1,431,893  ·         4.8 %  ·           -  │
·······························|·················|···············|·················|················|···············
|  Meme                        ·              -  ·            -  ·      1,994,811  ·         6.6 %  ·           -  │
·······························|·················|···············|·················|················|···············
|  Key                                                                                                             │
····················································································································
|  ◯  Execution gas for this method does not include intrinsic gas overhead                                        │
····················································································································
|  △  Cost was non-zero but below the precision setting for the currency display (see options)                     │
····················································································································
|  Toolchain:  hardhat                                                                                             │
····················································································································
root@1e49dbc520c1:/home/ubuntu/web3-tasks/advanced2-contract-dev/task1/meme-experience#
```


### error handle

#### 1. install dotnev error

description:
> npm install --save-dev dotenv
> report error:
> 13 silly packumentCache heap:4345298944 maxSize:1086324736 maxEntrySize:543162368
> 14 http fetch GET 200 https://registry.npmjs.org/install 547ms (cache miss)
> 15 verbose stack Error: could not determine executable to run
> 15 verbose stack     at getBinFromManifest (/root/.nvm/versions/node/v22.19.0/lib/node_modules/npm/node_modules/libnpmexec/lib/get-bin-from-manifest.js:17:23)
> 15 verbose stack     at exec (/root/.nvm/versions/node/v22.19.0/lib/node_modules/npm/node_modules/libnpmexec/lib/index.js:202:15)
> 15 verbose stack     at async Npm.exec (/root/.nvm/versions/node/v22.19.0/lib/node_modules/npm/lib/npm.js:207:9)
> 15 verbose stack     at async module.exports (/root/.nvm/versions/node/v22.19.0/lib/node_modules/npm/lib/cli/entry.js:74:5)
> 16 verbose pkgid install@0.13.0
> 17 error could not determine executable to run

resolve:
```shell
rm -rf .gitignore
npm install --save-dev dotenv
```

### 2. hardhat.config.js add deploy task error

description:
```shell
root@1e49dbc520c1:/home/ubuntu/web3-tasks/advanced2-contract-dev/task1/meme-experience# npx hardhat deploy --network localhost
Error HH9: Error while loading Hardhat's configuration.

You probably tried to import the "hardhat" module from your config or a file imported from it.
This is not possible, as Hardhat can't be initialized while its config is being defined.

To learn more about how to access the Hardhat Runtime Environment from different contexts go to https://hardhat.org/hre

HardhatError: HH9: Error while loading Hardhat's configuration.

You probably tried to import the "hardhat" module from your config or a file imported from it.
This is not possible, as Hardhat can't be initialized while its config is being defined.

To learn more about how to access the Hardhat Runtime Environment from different contexts go to https://hardhat.org/hre
    at Object.<anonymous> (/home/ubuntu/web3-tasks/advanced2-contract-dev/task1/meme-experience/node_modules/hardhat/src/internal/lib/hardhat-lib.ts:21:11)
    at Module._compile (node:internal/modules/cjs/loader:1706:14)
    at Object..js (node:internal/modules/cjs/loader:1839:10)
    at Module.load (node:internal/modules/cjs/loader:1441:32)
    at Function._load (node:internal/modules/cjs/loader:1263:12)
    at TracingChannel.traceSync (node:diagnostics_channel:322:14)
    at wrapModuleLoad (node:internal/modules/cjs/loader:237:24)
    at Module.require (node:internal/modules/cjs/loader:1463:12)
    at require (node:internal/modules/helpers:147:16)
    at Object.<anonymous> (/home/ubuntu/web3-tasks/advanced2-contract-dev/task1/meme-experience/hardhat.config.js:1:20)
```

resolve:

```shell
delete line in hardhat.config.js :
// const { ethers } = require("hardhat");
```