# Fusion - Contracts

![Made-With-Solidity](https://img.shields.io/badge/MADE%20WITH-SOLIDITY-000000.svg?colorA=222222&style=for-the-badge&logoWidth=14&logo=solidity)

## Deployments

![Made-With-Optimism](https://img.shields.io/badge/Deployed%20on-Optimism-ff0000.svg?colorA=222222&style=for-the-badge&logoWidth=14)
![Made-With-Base](https://img.shields.io/badge/Deployed%20on-Base-0000ff.svg?colorA=222222&style=for-the-badge&logoWidth=14)
![Made-With-Fraxtal](https://img.shields.io/badge/Deployed%20on-Fraxtal-000000.svg?colorA=222222&style=for-the-badge&logoWidth=14)
![Made-With-Unichain](https://img.shields.io/badge/Deployed%20on-Unichain-ff52f9.svg?colorA=222222&style=for-the-badge&logoWidth=14)

> Fusion is a smart contract wallet that leverages zero-knowledge proofs for authentication. Fusion Wallet is designed to accept payments in any ERC-20 tokens with the help of Gas Operators (Providers). This Providers provide you with quotes for the transaction and you can choose the best one for you.

These are the solidity smart contracts used in _[getFusion.tech](https://getFusion.tech/)_

## Contracts

- **Fusion** deployed to: [0xfa23217D680da5d755EBf601700800da809008B3](https://routescan.io/address/0xfa23217D680da5d755EBf601700800da809008B3)
- **FusionProxyFactory** deployed to: [0x26F230BCa86f02E73B487f583f9D98D54266b3B5](https://routescan.io/address/0x26F230BCa86f02E73B487f583f9D98D54266b3B5)
- **OpenBatchExecutor** deployed to: [0xDB6954b2fD7Ca28A30466452dfA34e6F73bfe70b](https://routescan.io/address/0xDB6954b2fD7Ca28A30466452dfA34e6F73bfe70b)
- **OpenBatchExecutorNoFailure** deployed to: [0x160860b934179D2F70da22eF85E20Cb4d0820c31](https://routescan.io/address/0x160860b934179D2F70da22eF85E20Cb4d0820c31)

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
npx hardhat run --network optimism scripts/deploy.js
```
