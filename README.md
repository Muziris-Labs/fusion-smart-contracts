# Fusion - Contracts

![Made-With-Solidity](https://img.shields.io/badge/MADE%20WITH-SOLIDITY-000000.svg?colorA=222222&style=for-the-badge&logoWidth=14&logo=solidity)
![Made-With-Wormhole](https://img.shields.io/badge/MADE%20WITH-wormhole-ffffff.svg?colorA=222222&style=for-the-badge&logoWidth=14)
![Made-With-Avalanche](https://img.shields.io/badge/Deployed%20on-Avalanche-ff0000.svg?colorA=222222&style=for-the-badge&logoWidth=14)
![Made-With-Optimism](https://img.shields.io/badge/Deployed%20on-Optimism-ff0000.svg?colorA=222222&style=for-the-badge&logoWidth=14)
![Made-With-Base](https://img.shields.io/badge/Deployed%20on-Base-0000ff.svg?colorA=222222&style=for-the-badge&logoWidth=14)

> Fusion is a multi-chain smart contract wallet that leverages zero-knowledge proofs and Wormhole for cross-chain deployments and authentication.

These are the solidity smart contracts used in _[getFusion.tech](https://getFusion.tech/)_

## Deployments

- **Avalanche Fuji (Base-Chain)**

  - Fusion - [0x2E03BAf7cAAee536e5680f8B210e48C89e18204A](https://testnet.routescan.io/address/0x2E03BAf7cAAee536e5680f8B210e48C89e18204A)
  - Fusion Forwarder - [0xfC417EE9c5ee1018acf3297a608982dD547fAc7C](https://testnet.routescan.io/address/0xfC417EE9c5ee1018acf3297a608982dD547fAc7C)
  - Factory Forwarder - [0x39Ba4C7C6538D1c6529C9562851444F26Cba8f9F](https://testnet.routescan.io/address/0x39Ba4C7C6538D1c6529C9562851444F26Cba8f9F)
  - Fusion Proxy Factory - [0x12d8f1C2e392a2A6864456393cDCb9790d83D639](https://testnet.routescan.io/address/0x12d8f1C2e392a2A6864456393cDCb9790d83D639)

- **Optimism Sepolia (Side-Chain)**

  - Fusion - [0x2E03BAf7cAAee536e5680f8B210e48C89e18204A](https://testnet.routescan.io/address/0x2E03BAf7cAAee536e5680f8B210e48C89e18204A)
  - Fusion Forwarder - [0xfC417EE9c5ee1018acf3297a608982dD547fAc7C](https://testnet.routescan.io/address/0xfC417EE9c5ee1018acf3297a608982dD547fAc7C)
  - Factory Forwarder - [0x39Ba4C7C6538D1c6529C9562851444F26Cba8f9F](https://testnet.routescan.io/address/0x39Ba4C7C6538D1c6529C9562851444F26Cba8f9F)
  - Fusion Proxy Factory - [0x12d8f1C2e392a2A6864456393cDCb9790d83D639](https://testnet.routescan.io/address/0x12d8f1C2e392a2A6864456393cDCb9790d83D639)

- **Base Sepolia (Side-Chain)**
  - Fusion - [0x2E03BAf7cAAee536e5680f8B210e48C89e18204A](https://testnet.routescan.io/address/0x2E03BAf7cAAee536e5680f8B210e48C89e18204A)
  - Fusion Forwarder - [0xfC417EE9c5ee1018acf3297a608982dD547fAc7C](https://testnet.routescan.io/address/0xfC417EE9c5ee1018acf3297a608982dD547fAc7C)
  - Factory Forwarder - [0x39Ba4C7C6538D1c6529C9562851444F26Cba8f9F](https://testnet.routescan.io/address/0x39Ba4C7C6538D1c6529C9562851444F26Cba8f9F)
  - Fusion Proxy Factory - [0x12d8f1C2e392a2A6864456393cDCb9790d83D639](https://testnet.routescan.io/address/0x12d8f1C2e392a2A6864456393cDCb9790d83D639)

#

> **Pre-requisites:**
>
> - Setup Node.js v18+ (recommended via [nvm](https://github.com/nvm-sh/nvm) with `nvm install 18`)
> - Install [npm](https://docs.npmjs.com/downloading-and-installing-node-js-and-npm)
> - Clone this repository

```bash
# Install dependencies
npm install

# fill environments
cp .env.example .env
```

## Development

```bash
# Compile all the contracts
npx hardhat compile

# Deploy on Avalanche Fuji, Check hardhat.config.js to check or add supported chains
npx hardhat run --network fuji scripts/deploy.js
```
