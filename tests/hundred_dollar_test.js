/* eslint-disable no-undef */
// Right click on the script name and hit "Run" to execute
import { expect } from "chai";
import { ethers } from "hardhat";


describe("HundredDollarOriginToken", function () {
  let game; 
  let user1;
  let user2;
  let user3;
  beforeEach(async function () {
    [user1, user2, user3] = await ethers.getSigners();

    const gameContract = await ethers.getContractFactory("HundredDollarGame");
    game = await gameContract.deploy(ethers.utils.parseEther("5.0"),60,ethers.constants.AddressZero);
    await game.deployed();
  })

  it("deploy",async function () {
    const info = await game.getGameInfo();
    expect(info[0]).to.equal(ethers.constants.AddressZero);
  })

  
  it("deposit 1 ether",async function () {
    const tx = await game.deposit(0,{value:ethers.utils.parseEther("1.0")});
    try {
      await tx.wait();
    } catch (error) {
        console.error(error);
    }
    
    const info = await game.getGameInfo();
    expect(info[3]).to.equal(ethers.utils.parseEther("1.0"));
  })

  it("bid 5 ether",async function () {
    try {
      const tx = await game.connect(user2).bid(0,{value:ethers.utils.parseEther("5.0")});
      await tx.wait();
    } catch (error) {
        console.error(error);
    }
    
    const info = await game.getGameInfo();
    expect(info[2]).to.equal(ethers.utils.parseEther("5.0"));
  })

  it("winner amount is 10",async function () {
    try {
      const tx = await game.connect(user2).bid(0,{value:ethers.utils.parseEther("5.0")});
      await tx.wait();
    } catch (error) {
        console.error(error);
    }
    try {
      const tx = await game.connect(user3).bid(0,{value:ethers.utils.parseEther("10.0")});
      await tx.wait();
    } catch (error) {
        console.error(error);
    }

    const info = await game.getGameInfo();
    expect(info[2]).to.equal(ethers.utils.parseEther("10.0"));
  })
});

describe("HundredDollarFungibleToken", function () {
  let game; 
  let owner;
  let user2;
  let user3;
  let fungibleToken; 
  beforeEach(async function () {
    [owner, user2, user3] = await ethers.getSigners();

    const tokenContract = await ethers.getContractFactory("CunningFox");
    fungibleToken = await tokenContract.deploy();
    await fungibleToken.deployed();

    await fungibleToken.transfer(user2.address,ethers.utils.parseEther("100.0"));
    await fungibleToken.transfer(user3.address,ethers.utils.parseEther("100.0"));

    const gameContract = await ethers.getContractFactory("HundredDollarGame");
    game = await gameContract.deploy(ethers.utils.parseEther("5.0"),60,fungibleToken.address);
    await game.deployed();

    await fungibleToken.connect(owner).approve(game.address,ethers.utils.parseEther("1000.0"));

    const allowanced = await fungibleToken.allowance(owner.address,game.address);

    await fungibleToken.connect(user2).approve(game.address,ethers.utils.parseEther("1000.0"));
    await fungibleToken.connect(user3).approve(game.address,ethers.utils.parseEther("1000.0"));
  })

  it("deploy",async function () {
    const info = await game.getGameInfo();
    expect(info[0]).to.equal(fungibleToken.address);
  })

  
  it("deposit 100 fts",async function () {
    const tx = await game.deposit(ethers.utils.parseEther("100.0"));
    try {
      await tx.wait();
    } catch (error) {
        console.error(error);
    }
    
    const info = await game.getGameInfo();
    expect(info[3]).to.equal(ethers.utils.parseEther("100.0"));
  })

  it("bid 5 fts",async function () {
    try {
      const tx = await game.connect(user2).bid(ethers.utils.parseEther("5.0"));
      await tx.wait();
    } catch (error) {
        console.error(error);
    }
    
    const info = await game.getGameInfo();
    expect(info[2]).to.equal(ethers.utils.parseEther("5.0"));
  })

  it("winner amount is 10 fts",async function () {
    try {
      const tx = await game.connect(user2).bid(ethers.utils.parseEther("5.0"));
      await tx.wait();
    } catch (error) {
        console.error(error);
    }
    try {
      const tx = await game.connect(user3).bid(ethers.utils.parseEther("10.0"));
      await tx.wait();
    } catch (error) {
        console.error(error);
    }

    const info = await game.getGameInfo();
    expect(info[2]).to.equal(ethers.utils.parseEther("10.0"));
  })
});