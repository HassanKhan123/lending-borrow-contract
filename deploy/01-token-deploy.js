const { network, ethers } = require("hardhat");

const {
  networkConfig,
  developmentChains,
} = require("../helper-hardhat-config");
const { ETHERSCAN_API_KEY } = require("../secret");
const { verify } = require("../utils/verify");

module.exports = async ({ getNamedAccounts, deployments }) => {
  const { deploy, log } = deployments;
  const { deployer } = await getNamedAccounts();
  const chainId = network.config.chainId;

  const args = ["0x0165b733e860b1674541BB7409f8a4743A564157"];

  const loan = await deploy("Lending", {
    from: deployer,
    log: true,
    args,
    waitConfirmations: network.config.blockConfirmations || 1,
  });

  if (!developmentChains.includes(network.name) && ETHERSCAN_API_KEY) {
    log("Verifying.....");
    await verify(loan.address, args);
  }
};

module.exports.tags = ["all", "Lending"];
