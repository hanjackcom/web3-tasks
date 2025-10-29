require("@nomicfoundation/hardhat-toolbox");
require("@openzeppelin/hardhat-upgrades");
require("dotenv").config();

const { task } = require("hardhat/config");

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

task("deploy", "Deploy the contracts", async () => {
  const signers = await ethers.getSigners();
  const deployer = signers[0];
  console.log("Deploying contracts with the account:", deployer.address);

  const MetaNodeToken = await ethers.getContractFactory("MetaNodeToken");
  metaNode = await MetaNodeToken.deploy(ethers.parseEther("1000000"));
  await metaNode.waitForDeployment();
  console.log("MetaNodeToken deployed to:", await metaNode.getAddress());

  const MetaNodeStake = await ethers.getContractFactory("MetaNodeStake");

  const metaNodeAddress = await metaNode.getAddress() // replace your MetaNode token address if your want to replace
  const startBlock = await ethers.provider.getBlockNumber() + 100;
  const endBlock = startBlock + 1000000;
  const metaNodePerBlock = ethers.parseEther("1"); // rewoard 1 MetaNode per block

  console.log("Deploying MetaNodeStake proxy...");
  const metaNodeStake = await upgrades.deployProxy(MetaNodeStake, [
    metaNodeAddress,
    startBlock,
    endBlock,
    metaNodePerBlock
  ], { initializer: 'initialize' });

  await metaNodeStake.waitForDeployment();
  console.log("MetaNodeStake deployed to:", await metaNodeStake.getAddress());
})