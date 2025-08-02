const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("StakedETH (sETH)", function () {
  let dETH, sETH, owner, user1, user2;

  beforeEach(async function () {
    [owner, user1, user2] = await ethers.getSigners();
  
    const DepositETH = await ethers.getContractFactory("DepositETH");
    dETH = await DepositETH.deploy();
    await dETH.waitForDeployment();
  
    const StakedETH = await ethers.getContractFactory("StakedETH");
    sETH = await StakedETH.deploy(await dETH.getAddress());
    await sETH.waitForDeployment();
  
    // Simulate ETH deposits
    await dETH.connect(user1).deposit({ value: ethers.parseEther("100") });
    await dETH.connect(user2).deposit({ value: ethers.parseEther("50") });
  
    // Approve staking contract to transfer dETH
    await dETH.connect(user1).approve(await sETH.getAddress(), ethers.parseEther("100"));
    await dETH.connect(user2).approve(await sETH.getAddress(), ethers.parseEther("50"));
  });  

  it("should allow user to stake and mint sETH", async function () {
    await sETH.connect(user1).stake(ethers.parseEther("10"));
    expect(await sETH.balanceOf(user1.address)).to.equal(ethers.parseEther("10"));
    expect(await sETH.totalStaked()).to.equal(ethers.parseEther("10"));
  });

  it("should allow unstaking and transfer back dETH", async function () {
    await sETH.connect(user1).stake(ethers.parseEther("10"));
    await sETH.connect(user1).unstake(ethers.parseEther("4"));
    expect(await sETH.balanceOf(user1.address)).to.equal(ethers.parseEther("6"));
    expect(await dETH.balanceOf(user1.address)).to.equal(ethers.parseEther("94"));
  });

  it("should return correct staker info", async function () {
    await sETH.connect(user1).stake(ethers.parseEther("12"));
    const stake = await sETH.getStakeInfo(user1.address);
    expect(stake.amount).to.equal(ethers.parseEther("12"));
    expect(stake.timestamp).to.be.gt(0);
  });

  it("should track total stakers correctly", async function () {
    await sETH.connect(user1).stake(ethers.parseEther("10"));
    await sETH.connect(user2).stake(ethers.parseEther("20"));
    expect(await sETH.getTotalStakers()).to.equal(2);
  });

  it("should remove staker on full unstake", async function () {
    await sETH.connect(user1).stake(ethers.parseEther("10"));
    await sETH.connect(user1).unstake(ethers.parseEther("10"));
    expect(await sETH.getTotalStakers()).to.equal(0);
  });
});
