const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Meme", function () {
  // let user1 = "0x2e55dd100abeB5ecD371eEDA26792Ab18bBA78aa";
  // let user2 = "0x4134c35B29e59d3BA487bcAB0591138Ca207E91A";
  let user1 = "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266";
  let user2 = "0x70997970C51812dc3A010C7d01b50e0d17dc79C8";
  let meme;
  let owner, addr1, addr2;

  beforeEach(async () => {
    [owner, addr1, addr2] = await ethers.getSigners();
    const Meme = await ethers.getContractFactory("Meme");
    meme = await Meme.deploy("hanjackcom", "HJC", 18, 100000000);
    await meme.waitForDeployment();
  });

  it("should get the balance of the contract", async () => {
    expect(await meme.balanceOf(owner.address)).to.equal(100000000);
  });

  it("should transfer tokens correctly", async () => {
    await meme.transfer(addr1.address, 1000);
    expect(await meme.balanceOf(addr1.address)).to.equal(950);
  });

  it("Should approve and transferFrom tokens", async () => {
    await meme.approve(addr1.address, 2000);
    expect(await meme.allowance(owner.address, addr1.address)).to.equal(2000);

    await meme.connect(addr1).transferFrom(owner.address, addr2.address, 1000);
    expect(await meme.balanceOf(addr2.address)).to.equal(950);
  });

  it("should allow owner to mint tokens", async () => {
    const initialSupply = await meme.getTotalSupply();
    await meme.mint(addr1.address, 5000);
    expect(await meme.balanceOf(addr1.address)).to.equal(5000);
    expect(await meme.getTotalSupply()).to.equal(initialSupply + BigInt(5000));
  });

  it("should allow owner to burn tokens", async () => {
    const initialSupply = await meme.getTotalSupply();
    await meme.burn(1000);
    expect(await meme.getTotalSupply()).to.equal(initialSupply - BigInt(1000));
  });

  it("should manage excluded from fees addresses", async () => {
    await meme.addExcludedFromFees(addr1.address);
    expect(await meme.getIsExcludedFromFees(addr1.address)).to.equal(true);

    await meme.removeExcludedFromFees(addr1.address);
    expect(await meme.getIsExcludedFromFees(addr1.address)).to.equal(false);
  });

});

describe("LiquidityPool", function () {
  let liquidityPool;
  let meme;
  let owner, addr1, addr2;

  this.beforeEach(async () => {
    [owner, addr1, addr2] = await ethers.getSigners();

    const Meme = await ethers.getContractFactory("Meme");
    meme = await Meme.deploy("hanjackcom", "HJC", 18, 100000000);
    await meme.waitForDeployment();

    const LiquidityPool = await ethers.getContractFactory("LiquidityPool");
    liquidityPool = await LiquidityPool.deploy(await meme.getAddress());
    await liquidityPool.waitForDeployment();
  });

  it("should deploy with correct meme token address", async () => {
    expect(await liquidityPool.getMemeToken()).to.equal(await meme.getAddress());
    expect(await liquidityPool.getOwner()).to.equal(owner.address);
  });

  it("should add liquidity correctly", async () => {
    await meme.approve(await liquidityPool.getAddress(), 10000);

    await liquidityPool.addLiquidity(5000, {value: ethers.parseEther("1")});

    const [ethReserve, tokenReserve, totalShares] = await liquidityPool.getPoolInfo();
    expect(ethReserve).to.equal(ethers.parseEther("1"));
    expect(tokenReserve).to.equal(5000);
    expect(totalShares).to.equal(ethers.parseEther("1"));
  });

  it("should remove liquidity correctly", async () => {
    await meme.approve(await liquidityPool.getAddress(), 10000);
    await liquidityPool.addLiquidity(5000, {value: ethers.parseEther("1")});

    const initialEthBalance = await ethers.provider.getBalance(owner.address);
    const intialTokenBalance = await meme.balanceOf(owner.address);

    const sharesToRemove = ethers.parseEther("0.5");
    await liquidityPool.removeLiquidity(sharesToRemove);
    const [ethReserve, tokenReserve] = await liquidityPool.getPoolInfo();
    expect(ethReserve).to.equal(ethers.parseEther("0.5"));
    expect(tokenReserve).to.equal(2500);
  });

  it("should swap ETH for tokens correctly", async () => {
    await meme.approve(await liquidityPool.getAddress(), 10000);
    await liquidityPool.addLiquidity(10000, {value: ethers.parseEther("2")});

    const initialTokenBalance = await meme.balanceOf(addr1.address);

    await liquidityPool.connect(addr1).swapETHForToken({value: ethers.parseEther("0.1")});

    const finalTokenBalance = await meme.balanceOf(addr1.address);
    expect(finalTokenBalance).to.be.gt(initialTokenBalance);
  });

  it("should swap tokens for ETH correctly", async () => {
    await meme.approve(await liquidityPool.getAddress(), 10000);
    await liquidityPool.addLiquidity(10000, {value: ethers.parseEther("2")});

    await meme.transfer(addr1.address, 1000);
    await meme.connect(addr1).approve(await liquidityPool.getAddress(), 500);

    const initialEthBalance = await ethers.provider.getBalance(addr1.address);
    await liquidityPool.connect(addr1).swapTokenForETH(500);
    const finalEthBalance = await ethers.provider.getBalance(addr1.address);

    expect(finalEthBalance).to.be.gt(initialEthBalance - ethers.parseEther("0.01")); // sub gas
  });

  it("should get swap price preview correctly", async () => {
    await meme.approve(await liquidityPool.getAddress(), 10000);
    await liquidityPool.addLiquidity(10000, {value: ethers.parseEther("1")});

    const ethToTokenPrice = await liquidityPool.getSwapPrice(ethers.parseEther("0.1"), true);
    const tokenToEthPrice = await liquidityPool.getSwapPrice(1000, false);

    expect(ethToTokenPrice).to.be.gt(0);
    expect(tokenToEthPrice).to.be.gt(0);
  });
});
