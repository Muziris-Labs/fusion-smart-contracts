// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../base/Verifier.sol";
import "./ProofHandler.sol";
import "../libraries/Conversion.sol";

interface IIndexer {
    function addTx(bytes32 _tx) external;

    function getServerHash() external view returns (bytes32);
}

interface IProxyFactory {
    function getFusionProxy(
        string memory domain
    ) external view returns (address);
}

contract GasToken is ERC20, Verifier, ProofHandler {
    event BuyTokens(
        string domain,
        uint256 chainId,
        bytes32 txHash,
        uint256 amount
    );

    event BurnTokens(
        string domain,
        uint256 chainId,
        bytes32 txHash,
        uint256 amount
    );

    mapping(uint256 => address) public indexers;

    address public GENESIS_ADDRESS;

    address public FUSION_PROXY_FACTORY;

    address public BuyVerifier;
    address public BurnVerifier;

    constructor() ERC20("GasToken", "GAS") {
        GENESIS_ADDRESS = msg.sender;
    }

    modifier onlyGenesis() {
        require(msg.sender == GENESIS_ADDRESS, "GAS Token: Not genesis");
        _;
    }

    function addIndexer(
        uint256 _chainId,
        address _indexer
    ) external onlyGenesis {
        require(
            indexers[_chainId] == address(0),
            "GAS Token: Indexer already exists"
        );
        indexers[_chainId] = _indexer;
    }

    function setFusionProxyFactory(address _factory) external onlyGenesis {
        FUSION_PROXY_FACTORY = _factory;
    }

    function setVerifiers(
        address _buyVerifier,
        address _burnVerifier
    ) external onlyGenesis {
        BuyVerifier = _buyVerifier;
        BurnVerifier = _burnVerifier;
    }

    function BuyAndIndex(
        bytes calldata proof,
        string memory domain,
        uint256 chainId,
        bytes32 txHash,
        uint256 amount
    ) external payable {
        require(
            indexers[chainId] != address(0),
            "GAS Token: Indexer not found"
        );

        {
            address fusionProxy = IProxyFactory(FUSION_PROXY_FACTORY)
                .getFusionProxy(domain);

            require(
                fusionProxy != address(0),
                "GAS Token: Fusion proxy not found"
            );

            bytes32 serverHash = IIndexer(indexers[chainId]).getServerHash();

            require(
                _verify(
                    proof,
                    serverHash,
                    bytes4(keccak256(abi.encodePacked(domain))),
                    chainId,
                    txHash,
                    amount,
                    BuyVerifier
                ),
                "GAS Token: Invalid proof"
            );

            IIndexer(indexers[chainId]).addTx(txHash);

            _mint(fusionProxy, amount);
        }

        emit BuyTokens(domain, chainId, txHash, amount);
    }

    function withdrawFees(
        bytes calldata proof,
        string memory domain,
        uint256 chainId,
        bytes32 txHash,
        uint256 estimatedGas
    ) external {
        address fusionProxy = IProxyFactory(FUSION_PROXY_FACTORY)
            .getFusionProxy(domain);

        require(fusionProxy != address(0), "GAS Token: Fusion proxy not found");

        require(
            balanceOf(fusionProxy) >= estimatedGas,
            "GAS Token: Insufficient balance"
        );

        bytes32 serverHash = IIndexer(indexers[chainId]).getServerHash();

        require(
            _verify(
                proof,
                serverHash,
                bytes4(keccak256(abi.encodePacked(domain))),
                chainId,
                txHash,
                estimatedGas,
                BuyVerifier
            ),
            "GAS Token: Invalid proof"
        );

        _burn(fusionProxy, estimatedGas);

        emit BurnTokens(domain, chainId, txHash, estimatedGas);
    }

    function _verify(
        bytes calldata _proof,
        bytes32 _serverHash,
        bytes4 _domain,
        uint256 chainId,
        bytes32 _txHash,
        uint256 _amount,
        address _verifier
    ) internal returns (bool) {
        bytes32[] memory publicInputs;

        require(isProofDuplicate(_proof) == false, "Proof already exists");

        // Add the proof to prevent reuse
        addProof(_proof);

        // Use scope here to limit variable lifetime and prevent `stack too deep` errors
        {
            publicInputs = new bytes32[](36);
            publicInputs[0] = _serverHash;
            publicInputs[1] = bytes32(uint256(uint32(_domain)));
            publicInputs[2] = bytes32(chainId);
            for (uint256 i = 3; i < 35; i++) {
                publicInputs[i] = Conversion.convertToPaddedByte32(
                    _txHash[i - 3]
                );
            }
            publicInputs[35] = bytes32(_amount);
        }

        return verifyProof(_proof, publicInputs, _verifier);
    }
}
