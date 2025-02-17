// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through node <script>.
//
// You can also run a script with npx hardhat run <script>. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const hre = require("hardhat");

async function estimateGas(contract, deployerAddress, args = []) {
  try {
    const factory = await hre.ethers.getContractFactory(contract);
    const deployTx = factory.getDeployTransaction(...args);
    const gasEstimate = await hre.ethers.provider.estimateGas({
      from: deployerAddress,
      data: deployTx.data,
    });
    return { success: true, gasEstimate };
  } catch (error) {
    return { success: false, error: error.message };
  }
}

async function deployContract(contractName, deployer, nonce, args = []) {
  const gasEstimation = await estimateGas(contractName, deployer.address, args);
  if (!gasEstimation.success) {
    throw new Error(
      `Gas estimation failed for ${contractName}: ${gasEstimation.error}`
    );
  }

  // Properly handle BigInt calculation
  const gasLimit = (gasEstimation.gasEstimate * BigInt(120)) / BigInt(100); // Add 20% buffer

  const contract = await hre.ethers.deployContract(contractName, args, {
    gasLimit: gasLimit,
    nonce: nonce, // Add specific nonce for deployment
  });

  await contract.waitForDeployment();
  return contract;
}

async function main(startingNonce) {
  try {
    const [deployer] = await hre.ethers.getSigners();
    console.log("Deploying contracts with account:", deployer.address);

    // Use provided nonce or get current nonce
    let currentNonce = startingNonce ?? (await deployer.getNonce());
    console.log("Starting deployment with nonce:", currentNonce);

    // First simulate all deployments
    const contractsToSimulate = [
      "Fusion",
      "FusionProxyFactory",
      "OpenBatchExecutor",
      "OpenBatchExecutorNoFailure",
    ];

    for (const contract of contractsToSimulate) {
      const gasEstimation = await estimateGas(contract, deployer.address);
      if (!gasEstimation.success) {
        throw new Error(
          `Pre-deployment simulation failed for ${contract}: ${gasEstimation.error}`
        );
      }
      console.log(
        `${contract} simulation successful. Estimated gas: ${gasEstimation.gasEstimate.toString()}`
      );
    }

    // If all simulations pass, proceed with actual deployments
    const fusion = await deployContract("Fusion", deployer, currentNonce);
    console.log("Fusion deployed to:", await fusion.getAddress());
    currentNonce++;

    const fusionProxyFactory = await deployContract(
      "FusionProxyFactory",
      deployer,
      currentNonce
    );
    console.log(
      "FusionProxyFactory deployed to:",
      await fusionProxyFactory.getAddress()
    );
    currentNonce++;

    const openBatchExecutor = await deployContract(
      "OpenBatchExecutor",
      deployer,
      currentNonce
    );
    console.log(
      "OpenBatchExecutor deployed to:",
      await openBatchExecutor.getAddress()
    );
    currentNonce++;

    const openBatchExecutorNoFailure = await deployContract(
      "OpenBatchExecutorNoFailure",
      deployer,
      currentNonce
    );
    console.log(
      "OpenBatchExecutorNoFailure deployed to:",
      await openBatchExecutorNoFailure.getAddress()
    );
    currentNonce++;

    console.log("Final nonce:", currentNonce);
    console.log("Total transactions:", 4);

    // Return all deployed addresses for verification
    return {
      fusion: await fusion.getAddress(),
      fusionProxyFactory: await fusionProxyFactory.getAddress(),
      openBatchExecutor: await openBatchExecutor.getAddress(),
      openBatchExecutorNoFailure: await openBatchExecutorNoFailure.getAddress(),
    };
  } catch (error) {
    console.error("Deployment failed:", error);
    process.exit(1);
  }
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
if (require.main === module) {
  main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
  });
} else {
  module.exports = { main };
}
