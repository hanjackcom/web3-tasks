const { task } = require("hardhat/config");

require("@nomicfoundation/hardhat-toolbox");
require("dotenv").config();

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
