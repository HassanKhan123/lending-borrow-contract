const { deployments, ethers, getNamedAccounts, network } = require("hardhat");
const { assert, expect, describe } = require("chai");

const {
  developmentChains,
  networkConfig,
} = require("../helper-hardhat-config");

describe("Raffle", () => {
  let token, deployer;
  let chainId = network.config.chainId;

  beforeEach(async () => {
    deployer = (await getNamedAccounts()).deployer;
    await deployments.fixture(["Lending"]);
    token = await ethers.getContract("Lending", deployer);
    console.log(token);
  });
});
