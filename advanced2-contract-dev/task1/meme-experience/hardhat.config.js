const { task } = require("hardhat/config");

require("@nomicfoundation/hardhat-toolbox");
require("dotenv").config();
require("solidity-coverage");
require("hardhat-gas-reporter");

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.28",
  networks: {
    localhost: {
      url: "http://0.0.0.0:8545"
    },
    sepolia: {
      url: `https://sepolia.infura.io/v3/${process.env.INFURA_API_KEY}`,
      accounts: [process.env.PK]
    }
  },
  gasReporter: {
    currency: 'ETH',
    // L1: "ethereum",
    // coinmarketcap: process.env.COINMARKETCAP_API_KEY,
    etherscan: process.env.ETHERSCAN_API_KEY,
    // gasPriceApi: "https://api.etherscan.io/api?module=proxy&action=eth_gasPrice",
    outputFile: "gas-report.txt",
    enabled: (process.env.REPORT_GAS) ? true : false,
    // offline: true,
  }
};

task("deploy", "Deploy the Meme & LiquidityPool contract", async () => {
  const [deployer] = await ethers.getSigners();
  console.log("Deploying contracts with the account:", deployer.address);

  const Meme = await ethers.getContractFactory("Meme");
  const meme = await Meme.deploy("hanjackcom", "HJC", 18, 100000000);
  await meme.waitForDeployment();
  console.log("Meme deployed to:", await meme.getAddress());

  const LiquidityPool = await ethers.getContractFactory("LiquidityPool");
  const liquiditPool = await LiquidityPool.deploy(await meme.getAddress());
  await liquiditPool.waitForDeployment();
  console.log("LiquidityPool deployed to:", await liquiditPool.getAddress());
});
