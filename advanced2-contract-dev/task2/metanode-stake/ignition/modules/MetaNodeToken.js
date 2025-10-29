// This setup uses Hardhat Ignition to manage smart contract deployments.
// Learn more about it at https://hardhat.org/ignition

const { buildModule } = require("@nomicfoundation/hardhat-ignition/modules");
const { ethers } = require("hardhat");

module.exports = buildModule("MetaNodeTokenModule", (m) => {
  const metaNodeToken = m.contract("MetaNodeToken", [ethers.parseEther("1000000")]);

  return { metaNodeToken };
});
