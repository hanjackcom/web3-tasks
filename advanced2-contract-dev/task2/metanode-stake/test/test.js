const { ethers, upgrades } = require("hardhat");
const { expect } = require("chai");

describe("MetaNodeStake Contract Tests", function () {
  let metaNodeStake;
  let metaNode;
  let owner, user1, user2;

  beforeEach(async function () {
    const signers = await ethers.getSigners();
    owner = signers[0];
    user1 = signers[1];
    user2 = signers[2];

    const MetaNodeToken = await ethers.getContractFactory("MetaNodeToken");
    metaNode = await MetaNodeToken.deploy(ethers.parseEther("1000000"));
    await metaNode.waitForDeployment();

    const MetaNodeStake = await ethers.getContractFactory("MetaNodeStake");
    const startBlock = await ethers.provider.getBlockNumber() + 10;
    const endBlock = startBlock + 1000000;
    const metaNodePerBlock = ethers.parseEther("1");

    metaNodeStake = await upgrades.deployProxy(MetaNodeStake, [
      await metaNode.getAddress(),
      startBlock,
      endBlock,
      metaNodePerBlock
    ], { initializer: 'initialize' });
    await metaNodeStake.waitForDeployment();

    // transfer a little of token to stake contract for rewarding.
    await metaNode.transfer(await metaNodeStake.getAddress(), ethers.parseEther("100000"));

    // add ETH pool, because of pid = 0
    await metaNodeStake.addPool(
      "0x0000000000000000000000000000000000000000",
      ethers.parseEther("100"), // weight
      ethers.parseEther("0.01"), // min stake amount eth
      100 // lock 100 blocks when unstaking
    );

    console.log("MetaNodeStake deployed to:", await metaNodeStake.getAddress());
    console.log("MetaNode deployed to:", await metaNode.getAddress());
    console.log("Owner address:", owner.address);
  });

  describe("Basic connection and verification of contracts", function () {
    it("Should verify contract address exist", async function () {
      const contractAddress = await metaNodeStake.getAddress();
      const code = await ethers.provider.getCode(contractAddress);
      console.log("Contract code exists:", code != "0x");
      console.log("Code length:", code.length);
      expect(code).to.not.equal("0x");
    });

    it("Should get contract's basic info", async function () {
      try {
        const poolLength = await metaNodeStake.poolLength();
        const startBlock = await metaNodeStake.startBlock();
        const endBlock = await metaNodeStake.endBlock();
        const metaNodePerBlock = await metaNodeStake.metaNodePerBlock();

        console.log("Pool length:", poolLength.toString());
        console.log("Start block:", startBlock.toString());
        console.log("End block:", endBlock.toString());
        console.log("MetaNode per block:", ethers.formatEther(metaNodePerBlock));

        expect(poolLength).to.be.a('bigint');
        expect(startBlock).to.be.a('bigint');
        expect(endBlock).to.be.a('bigint');
        expect(metaNodePerBlock).to.be.a('bigint');
      } catch (error) {
        console.log("Error calling contract functions:", error.message);

        // try call directly for verifiing response or not.
        try {
          const contractAddress = await metaNodeStake.getAddress();
          const result = await ethers.privider.call({
            to: contractAddress,
            data: "0x081e3eda" // poolLength() function selector
          });
          console.log("Direct call result:", result)
        } catch (directError) {
          console.log("Direct call also failed:", directError.message)
        }

        throw error;
      }
    });
  });

  describe("Pool management", function () {
    it("Should add a new pool correctly", async function () {
      try {
        const initialPoolLength = await metaNodeStake.poolLength();
        console.log("Initial pool length:", initialPoolLength.toString());

        // add a test token pool, because ETH have added in beforeEatch
        const testTokenAddress = "0x9fe46736679d2d9a65f0992f2272de9f3c7fa6e0" // HJC token
        const poolWeight = ethers.parseEther("100");
        const minDepositAmount = ethers.parseEther("1");
        const unstakeLockedBlocks = 100;

        await metaNodeStake.connect(owner).addPool(
          testTokenAddress,
          poolWeight,
          minDepositAmount,
          unstakeLockedBlocks
        );

        const newPoolLength = await metaNodeStake.poolLength();
        expect(newPoolLength).to.equal(initialPoolLength + 1n);

        console.log("Successfully added new pool, new length:", newPoolLength.toString());
      } catch (error) {
        console.log("Error in pool management test:", error.message);
        throw error;
      }
    });
  });

  describe("ETH stake function", function () {
    it("Should stake ETH correctly", async function () {
      try {
        const depositAmount = ethers.parseEther("0.1");

        // ETH pool id = 0
        const pool = await metaNodeStake.pools(0);
        console.log("Pool 0 address:", pool.poolAddress);
        console.log("Min deposit amount:", ethers.formatEther(pool.minDepositAmount));

        const userBalance = await ethers.provider.getBalance(user1.address);
        console.log("User1 balance:", ethers.formatEther(userBalance));

        const tx = await metaNodeStake.connect(user1).depositETH({
          value: depositAmount
        });
        await tx.wait();

        const balance = await metaNodeStake.stakingBalance(0, user1.address);
        expect(balance).to.equal(depositAmount);

        console.log("Successfully deposited ETH:", ethers.formatEther(balance));
      } catch (error) {
        console.log("Error in ETH staking test:", error.message)
        throw error;
      }
    });
  });

  describe("Calculating reward", function () {
    it("Should calculate pending reward correctly", async function () {
      try {
        // check user's pending reward of ETH pool
        const pendingReward = await metaNodeStake.pendingMetaNode(0, user1.address);
        console.log("Pending reward for user1:", ethers.formatEther(pendingReward));

        expect(pendingReward).to.be.a('bigint');
      } catch (error) {
        console.log("Error in reward calculation test:", error.message);
        throw error;
      }
    });
  });

  describe("Access Control", function () {
    it("Should check admin role", async function () {
      try {
        const ADMIN_ROLE = await metaNodeStake.ADMIN_ROLE();
        const hasAdminRole = await metaNodeStake.hasRole(ADMIN_ROLE, owner.address);

        expect(hasAdminRole).to.be.true;
        console.log("Owner has admin role:", hasAdminRole);
        console.log("Admin role hash:", ADMIN_ROLE);
      } catch (error) {
        console.log("Error in admin role test:", error.message);
        throw error;
      }
    });

    it("Shouldn't add pool, if not ADMIN_ROLE ", async function () {
      try {
        await expect(
          metaNodeStake.connect(user1).addPool(
            "0x9fe46736679d2d9a65f0992f2272de9f3c7fa6e0", // HJC token
            ethers.parseEther("100"),
            ethers.parseEther("1"),
            100
          )
        ).to.be.reverted;

        console.log("Non-admin correctly prevented from adding pool");
      } catch (error) {
        console.log("Error in non-admin test:", error.message);
        throw error;
      }
    });
  });

});
