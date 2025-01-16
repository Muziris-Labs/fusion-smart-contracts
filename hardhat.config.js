require("@nomicfoundation/hardhat-toolbox");
require("dotenv").config();
require("@tenderly/hardhat-tenderly");

const PRIVATE_KEY = process.env.PRIVATE_KEY;

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: {
    version: "0.8.24",
    settings: {
      optimizer: {
        enabled: true,
        runs: 800,
        details: {
          yulDetails: {
            optimizerSteps: "u",
          },
        },
      },
      evmVersion: "paris",
      viaIR: true,
    },
  },
  networks: {
    pegasus: {
      url: `https://replicator.pegasus.lightlink.io/rpc/v1`,
      accounts: [PRIVATE_KEY],
    },
    opSepolia: {
      url: `https://sepolia.optimism.io/`,
      chainId: 11155420,
      accounts: [PRIVATE_KEY],
    },
    optimism: {
      url: `https://optimism-rpc.publicnode.com`,
      accounts: [PRIVATE_KEY],
    },
    base: {
      url: `https://base-rpc.publicnode.com`,
      accounts: [PRIVATE_KEY],
    },
    mode: {
      url: `https://1rpc.io/mode`,
      accounts: [PRIVATE_KEY],
    },
    baseSepolia: {
      url: `https://sepolia.base.org`,
      accounts: [PRIVATE_KEY],
    },
    modeSepolia: {
      url: `https://sepolia.mode.network`,
      accounts: [PRIVATE_KEY],
    },
    amoy: {
      url: `https://rpc-amoy.polygon.technology`,
      accounts: [PRIVATE_KEY],
    },
    fuji: {
      url: "https://api.avax-test.network/ext/bc/C/rpc",
      accounts: [PRIVATE_KEY],
    },
    fraxtal: {
      url: "https://rpc.frax.com",
      accounts: [PRIVATE_KEY],
    },
    moonbeam: {
      url: "https://moonbeam-rpc.publicnode.com",
      accounts: [PRIVATE_KEY],
    },
    astar: {
      url: "https://1rpc.io/astr",
      accounts: [PRIVATE_KEY],
    },
  },
  etherscan: {
    apiKey: {
      pegasus: "your API key",
      opSepolia: "89K6NC1QZIUZSA6A6S5SY1N3DVIBCJCD3A",
      optimism: "89K6NC1QZIUZSA6A6S5SY1N3DVIBCJCD3A",
      Base: "BZP99H9U5SEDZTTP3BIBUYE5X2TMM9PX5Q",
      baseSepolia: "BZP99H9U5SEDZTTP3BIBUYE5X2TMM9PX5Q",
      mode: "your API key",
      amoy: "B66XTC9JBFDKZDANXSVSYK91INPIFW7KT5",
      fuji: "your API key",
      Fraxtal: "VEFPEUSAVJHK9NGP52KU69AUFJ4YKIS44X",
      moonbeam: "HV1RAP2QJVSE1HUZK63PG31C7EIJINYJA4",
      astar: "your API key",
    },
    customChains: [
      {
        network: "pegasus",
        chainId: 1891,
        urls: {
          apiURL: "https://pegasus.lightlink.io/api",
          browserURL: "https://pegasus.lightlink.io/",
        },
      },
      {
        network: "opSepolia",
        chainId: 11155420,
        urls: {
          apiURL: "https://api-sepolia-optimistic.etherscan.io/api",
          browserURL: "https://sepolia-optimism.etherscan.io/",
        },
      },
      {
        network: "baseSepolia",
        chainId: 84532,
        urls: {
          apiURL: "https://api-sepolia.basescan.org/api",
          browserURL: "https://sepolia.basescan.org/",
        },
      },
      {
        network: "optimism",
        chainId: 10,
        urls: {
          apiURL: "https://api-optimistic.etherscan.io/api",
          browserURL: "https://optimistic.etherscan.io/",
        },
      },
      {
        network: "Base",
        chainId: 8453,
        urls: {
          apiURL: "https://api.basescan.org/api",
          browserURL: "https://basescan.org/",
        },
      },
      {
        network: "mode",
        chainId: 34443,
        urls: {
          apiURL: "https://explorer.mode.network/api/",
          browserURL: "https://explorer.mode.network/",
        },
      },
      {
        network: "amoy",
        chainId: 80002,
        urls: {
          apiURL: "https://api-amoy.polygonscan.com/api",
          browserURL: "https://amoy.polygonscan.com/",
        },
      },
      {
        network: "fuji",
        chainId: 43113,
        urls: {
          apiURL:
            "https://api.routescan.io/v2/network/testnet/evm/43113/etherscan",
          browserURL: "https://c-chain.snowtrace.io",
        },
      },
      {
        network: "Fraxtal",
        chainId: 252,
        urls: {
          apiURL: "https://api.fraxscan.com/api",
          browserURL: "https://fraxscan.com/",
        },
      },
      {
        network: "moonbeam",
        chainId: 1284,
        urls: {
          apiURL: "https://api-moonbeam.moonscan.io/api",
          browserURL: "https://moonbeam.moonscan.io/",
        },
      },
      {
        network: "astar",
        chainId: 592,
        urls: {
          apiURL: "https://astar.blockscout.com/api",
          browserURL: "https://astar.blockscout.com/",
        },
      },
    ],
  },
};
