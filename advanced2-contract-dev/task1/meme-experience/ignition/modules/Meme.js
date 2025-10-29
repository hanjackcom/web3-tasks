// This setup uses Hardhat Ignition to manage smart contract deployments.
// Learn more about it at https://hardhat.org/ignition

const { buildModule } = require("@nomicfoundation/hardhat-ignition/modules");

module.exports = buildModule("MemeModule", (m) => {
  const meme = m.contract("Meme", ["hanjackcom", "HJC", 18, 100000000]);

  return { meme };
});
