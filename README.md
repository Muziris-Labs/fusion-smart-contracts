# Fusion - Contracts

![Made-With-Solidity](https://img.shields.io/badge/MADE%20WITH-SOLIDITY-000000.svg?colorA=222222&style=for-the-badge&logoWidth=14&logo=solidity)
![Made-With-Fraxtal](https://img.shields.io/badge/Deployed%20on-Fraxtal-fef8f4.svg?colorA=222222&style=for-the-badge&logoWidth=14)
![Made-With-Optimism](https://img.shields.io/badge/Deployed%20on-Optimism-ff0000.svg?colorA=222222&style=for-the-badge&logoWidth=14)

> Fusion is a multi-chain smart contract wallet that leverages zero-knowledge proofs for cross-chain deployments and authentication.

> Gas Tokens (GAS) are zk-powered ERC-20 token to streamline gas payments across all compatible networks within the Fusion ecosystem.

These are the solidity smart contracts used in the _[getFusion.today](https://getFusion.today/)_ hackathon project at [Fraxtal Hackathon 2024](https://dorahacks.io/hackathon/fraxtal/).

## Deployments

- **Fraxtal (Base-Chain)**

  - Fusion - [0xd17Dd62290EcdEa48e5029a4fBd519245C911c19](https://fraxscan.com/address/0xd17Dd62290EcdEa48e5029a4fBd519245C911c19)
  - Fusion Forwarder - [0x0B62BDA8EcE17AFfa7adAe16bBaBBC8584A30016](https://fraxscan.com/address/0x0B62BDA8EcE17AFfa7adAe16bBaBBC8584A30016)
  - Factory Forwarder - [0x40C92d2E370b3d3944fDd90c922a407F02D286d1](https://fraxscan.com/address/0x40C92d2E370b3d3944fDd90c922a407F02D286d1)
  - Fusion Proxy Factory - [0x44950f083691828A07c17d2A927B435e8B272F6D](https://fraxscan.com/address/0x44950f083691828A07c17d2A927B435e8B272F6D)
  - Fusion Vault - [0x1275917daAE6389C61c7B1E8199724D0b46Ed10f](https://fraxscan.com/address/0x1275917daAE6389C61c7B1E8199724D0b46Ed10f)

- **Optimism (Side-Chain)**

  - Fusion - [0xE876ccf876A21Dd429D7f368e5b6f8bdAE31Ff8f](https://optimistic.etherscan.io/address/0xE876ccf876A21Dd429D7f368e5b6f8bdAE31Ff8f)
  - Fusion Forwarder - [0x95A847284488C6E57001F1245813a0aCcC709f07](https://optimistic.etherscan.io/address/0x95A847284488C6E57001F1245813a0aCcC709f07)
  - Factory Forwarder - [0x06A927Cf54B15d4178F0e3EC9ae85De5770B7CA7](https://optimistic.etherscan.io/address/0x06A927Cf54B15d4178F0e3EC9ae85De5770B7CA7)
  - Fusion Proxy Factory - [0x63949B7b906417c555136028391699E2B5adb381](https://optimistic.etherscan.io/address/0x63949B7b906417c555136028391699E2B5adb381)
  - Fusion Vault - [0x3705505C5690a836b33736CD13568Ee8700D35c4](https://optimistic.etherscan.io/address/0x3705505C5690a836b33736CD13568Ee8700D35c4)

- **Gas Token (ERC-20 | Fraxtal)**

  - Token - [0x614ae60954f0AEdd172141A9C52052a8B422DEfd](https://fraxscan.com/address/0x614ae60954f0AEdd172141A9C52052a8B422DEfd)
  - Indexer - [0xd4B57a2d4aA433FC59b062a9D8f87972d5654430](https://fraxscan.com/address/0xd4B57a2d4aA433FC59b062a9D8f87972d5654430)
  - Indexer Proxy Factory - [0x0bFc5a5ea52843aeB2C82a436403c52d43913229](https://fraxscan.com/address/0x0bFc5a5ea52843aeB2C82a436403c52d43913229)

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
npx hardhat run --network fraxtal scripts/deploy.js
```
