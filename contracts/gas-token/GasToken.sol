// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../base/Verifier.sol";
import "../handler/ProofHandler.sol";
import "../libraries/Conversion.sol";
import "../interfaces/IIndexerProxyFactory.sol";
import "../interfaces/IIndexer.sol";

/**
 * @title GasToken - A token contract that allows users to buy and burn gas tokens.
 * @author Anoy Roy Chowdhury - <anoy@valerium.id>
 * @notice Allows users to buy and burn gas tokens using server proofs.
 */

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

    // Mapping of chainId to indexer address
    mapping(uint256 => address) public indexers;

    // The address of the genesis
    address public GENESIS_ADDRESS;

    // The address of the BuyVerifier and BurnVerifier
    address public CreditVerifier;

    // Initializing the token with the name and symbol
    constructor() ERC20("GasToken", "GAS") {
        GENESIS_ADDRESS = msg.sender;
    }

    modifier onlyGenesis() {
        require(msg.sender == GENESIS_ADDRESS, "GAS Token: Not genesis");
        _;
    }

    /**
     * @notice Adds an indexer to the contract
     * @param _chainId  The chain id of the chain to index
     * @param _indexer The address of the indexer
     */
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

    /**
     *  @notice Sets the credit verifier
     * @param _creditVerifier The address of the credit verifier
     */
    function setVerifiers(address _creditVerifier) external onlyGenesis {
        CreditVerifier = _creditVerifier;
    }

    /**
     * @notice Buys gas tokens and indexes the transaction
     * @param proof The server proof
     * @param domain The domain of the request
     * @param chainId The chain id of the chain to index
     * @param txHash The hash of the transaction
     * @param amount The amount of tokens to buy
     */
    function BuyAndIndex(
        bytes calldata proof,
        string memory domain,
        address fusionAddress,
        uint256 chainId,
        bytes32 txHash,
        uint256 amount
    ) external payable {
        require(
            indexers[chainId] != address(0),
            "GAS Token: Indexer not found"
        );

        {
            bytes32 serverHash = IIndexer(indexers[chainId]).getServerHash();

            require(
                _verify(
                    proof,
                    serverHash,
                    bytes4(keccak256(abi.encodePacked(domain))),
                    chainId,
                    txHash,
                    amount,
                    0,
                    msg.sender,
                    CreditVerifier
                ),
                "GAS Token: Invalid proof"
            );

            IIndexer(indexers[chainId]).addTx(txHash);

            _mint(fusionAddress, amount);
        }

        emit BuyTokens(domain, chainId, txHash, amount);
    }

    /**
     * @notice Burns gas tokens and indexes the transaction
     * @param proof The server proof
     * @param domain The domain of the request
     * @param chainId The chain id of the chain to index
     * @param txHash The hash of the transaction
     * @param estimatedGas The amount of tokens to burn
     */
    function withdrawFees(
        bytes calldata proof,
        string memory domain,
        address fusionAddress,
        uint256 chainId,
        bytes32 txHash,
        uint256 estimatedGas
    ) external {
        require(
            balanceOf(fusionAddress) >= estimatedGas,
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
                1,
                msg.sender,
                CreditVerifier
            ),
            "GAS Token: Invalid proof"
        );

        _burn(fusionAddress, estimatedGas);

        emit BurnTokens(domain, chainId, txHash, estimatedGas);
    }

    /**
     * @notice Verifies the server proof
     * @param _proof The proof to be verified
     * @param _serverHash The hash of the server
     * @param _domain The domain of the request
     * @param chainId The chain id of the chain to index
     * @param _txHash The hash of the transaction
     * @param _amount The amount of tokens to buy
     * @param _verifier The address of the verifier
     */
    function _verify(
        bytes calldata _proof,
        bytes32 _serverHash,
        bytes4 _domain,
        uint256 chainId,
        bytes32 _txHash,
        uint256 _amount,
        uint256 tx_type,
        address _signingAddress,
        address _verifier
    ) internal returns (bool) {
        bytes32[] memory publicInputs;

        require(isProofDuplicate(_proof) == false, "Proof already exists");

        // Add the proof to prevent reuse
        addProof(_proof);

        // Use scope here to limit variable lifetime and prevent `stack too deep` errors
        {
            publicInputs = new bytes32[](38);
            publicInputs[0] = _serverHash;
            publicInputs[1] = bytes32(uint256(uint32(_domain)));
            publicInputs[2] = bytes32(chainId);
            for (uint256 i = 3; i < 35; i++) {
                publicInputs[i] = Conversion.convertToPaddedByte32(
                    _txHash[i - 3]
                );
            }
            publicInputs[35] = bytes32(_amount);
            publicInputs[36] = bytes32(tx_type);
            publicInputs[37] = bytes32(uint256(uint160(_signingAddress)));
        }

        return verifyProof(_proof, publicInputs, _verifier);
    }
}
