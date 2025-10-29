// This setup uses Hardhat Ignition to manage smart contract deployments.
// Learn more about it at https://hardhat.org/ignition

const { buildModule } = require("@nomicfoundation/hardhat-ignition/modules");

module.exports = buildModule("MetaNodeStakeModule", (m) => {
  const startBlock = 1 + 10;
  const endBlock = startBlock + 1000000;
  const metaNodePerBlock = ethers.parseEther("1");

  const metaNodeStake = m.contract("MetaNodeStake");
  m.call(metaNodeStake, "initialize", [
    "0x5FbDB2315678afecb367f032d93F642f64180aa3", // add metaNodeToken address after deploy MetaNodeToken
    startBlock,
    endBlock,
    metaNodePerBlock
  ]);

  return { metaNodeStake };
});
