const { expect } = require("chai");
const { ethers } = require("hardhat");
const { UniswapV2Factory, UniswapV2Router02, WETH9 } = require("@uniswap/v2-periphery");

describe("Meme", function () {
  // let user1 = "0x2e55dd100abeB5ecD371eEDA26792Ab18bBA78aa";
  // let user2 = "0x4134c35B29e59d3BA487bcAB0591138Ca207E91A";
  // let user1 = "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266";
  // let user2 = "0x70997970C51812dc3A010C7d01b50e0d17dc79C8";
  let meme;
  let owner, addr1, addr2;

  beforeEach(async () => {
    [owner, addr1, addr2] = await ethers.getSigners();
    const Meme = await ethers.getContractFactory("Meme");
    meme = await Meme.deploy("hanjackcom", "HJC", 100000000);
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

  it("should manage excluded from fees addresses", async () => {
    await meme.setIsExcludedFromFees(addr1.address, true);
    expect(await meme.getIsExcludedFromFees(addr1.address)).to.equal(true);

    await meme.setIsExcludedFromFees(addr1.address, false);
    expect(await meme.getIsExcludedFromFees(addr1.address)).to.equal(false);
  });

  it("should manage exempt addresses", async () => {
    await meme.setExemption(addr1.address, true);
    expect(await meme.getExemption(addr1.address)).to.equal(true);

    await meme.setExemption(addr1.address, false);
    expect(await meme.getExemption(addr1.address)).to.equal(false);
  });

});

describe("LiquidityPool", function () {
  let liquidityPool;
  let weth;
  let meme;
  let pair;
  let owner, addr1, addr2;

  beforeEach(async () => {
    [owner, addr1, addr2] = await ethers.getSigners();

    const Meme = await ethers.getContractFactory("Meme");
    meme = await Meme.deploy("hanjackcom", "HJC", 100000000n);
    await meme.waitForDeployment();

    // const deadline = Math.floor(new Date('2025-12-31T23:59:59').getTime()/1000);
    const deadline = Math.floor(Date.now() / 1000) + 864000; // 10 days

    const WETHFactory = await ethers.getContractFactory("WETH9");
    weth = await WETHFactory.deploy();
    await weth.deployed();
    console.log("WETH deployed to:", await weth.getAddress());

    const Factory = await ethers.getContractFactory("UniswapV2Factory");
    const factory = await Factory.deploy(owner.address);
    await factory.waitForDeployment();

    const RouterFactory = await ethers.getContractFactory("UniswapV2Router02");
    const router = await RouterFactory.deploy(await factory.getAddress(), await weth.getAddress());
    await router.deployed();
    console.log("UniswapV2Router02 depoyed to:", await router.getAddress());

    const LiquidityPool = await ethers.getContractFactory("LiquidityPool");
    liquidityPool = await LiquidityPool.deploy(router);
    await liquidityPool.waitForDeployment();

    await meme.approve(await liquidityPool.getAddress(), ethers.MaxUint256);
  });

  it("should add liquidity correctly", async () => {
    expect(await liquidityPool.owner()).to.equal(owner.address);

    await liquidityPool.addLiquidity(meme, 5000, 0, deadline, {value: ethers.parseEther("1")});

    pair = await liquidityPool.getPairAddress(meme);
    expect(pair).not.to.equal(0);

    const [_reserve0, _reserve1, _blockTimestampLast] = await pair.getReserves();
    expect(_reserve0).to.equal(ethers.parseEther("1"));
    expect(_reserve1).to.equal(5000);
  });

  it("should remove liquidity correctly", async () => {
    await liquidityPool.removeLiquidity(meme, 5000, 0, 0, deadline);
    const [ethReserve, tokenReserve] = await liquidityPool.getPoolInfo();
    
    const [_reserve0, _reserve1, _blockTimestampLast] = await pair.getReserves();
    expect(_reserve0).to.equal(ethers.parseEther("1"));
    expect(_reserve1).to.equal(5000);
  });

  it("should swap ETH for tokens correctly", async () => {
    // await meme.approve(await pair.getAddress(), 10000);
    await liquidityPool.addLiquidity(meme, 10000, 0, deadline, {value: ethers.parseEther("2")});

    const tokensOut = await liquidityPool.swapETHForTokens(meme, 0, deadline, {value: ethers.parseEther("1")});

    const wethBalance = await weth.balanceOf(await pair.getAddress());
    const tokenBalance = await meme.balanceOf(await pair.getAddress());
    expect(tokensOut).to.be.gt(0);
    expect(wethBalance).to.be.gt(0);
    expect(tokenBalance).to.be.gt(0);
  });

  it("should swap tokens for ETH correctly", async () => {
    // await meme.approve(await pair.getAddress(), 10000);
    await liquidityPool.addLiquidity(meme, 10000, 0, deadline, {value: ethers.parseEther("2")});

    const wethsOut = await liquidityPool.swapTokensForETH(meme, 5000, 0, deadline);

    const wethBalance = await weth.balanceOf(await pair.getAddress());
    const tokenBalance = await meme.balanceOf(await pair.getAddress());
    expect(wethsOut).to.be.gt(0);
    expect(wethBalance).to.be.gt(0);
    expect(tokenBalance).to.be.gt(0);
  });

  it("should get swap price preview correctly", async () => {
    // await meme.approve(await liquidityPool.getAddress(), 10000);
    // await liquidityPool.addLiquidity(10000, {value: ethers.parseEther("1")});

    // const ethToTokenPrice = await liquidityPool.getSwapPrice(ethers.parseEther("0.1"), true);
    // const tokenToEthPrice = await liquidityPool.getSwapPrice(1000, false);

    expect(pair.price0CumulativeLast).to.be.gt(0);
    expect(pair.price1CumulativeLast).to.be.gt(0);
  });
});
