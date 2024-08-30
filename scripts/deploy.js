// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const hre = require("hardhat");

async function main() {
  const [deployer] = await hre.ethers.getSigners();

  console.log("Deploying contracts with the account:", deployer.address);

  const contract = await hre.ethers.deployContract(
    "FusionProxyFactory",
    [
      "0x40C92d2E370b3d3944fDd90c922a407F02D286d1",
      "0x3411eE3ACc6eC027bff5C60D5463f1f0BB9C5f2e",
      "10005",
      "0x93BAD53DDfB6132b0aC8E37f6029163E63372cEE",
      "10004",
    ],
    {
      gasLimit: 10000000,
    }
  );

  console.log("Contract address:", await contract.getAddress());
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
