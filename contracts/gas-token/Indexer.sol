// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

import "../common/StorageAccessible.sol";
import "../common/Singleton.sol";

/**
 * @title Indexer - Indexes transactions for the base chain
 * @author Anoy Roy Chowdhury - <anoy@valerium.id>
 * @notice Used by the base chain to index transactions and prevent duplicates
 */

contract Indexer is Singleton, StorageAccessible {
    // The address of the genesis
    address private GENESIS_ADDRESS;

    // The chain id of the chain to index
    uint256 public chainId;

    // The sentinel value for the transaction list
    bytes32 internal constant SENTINEL_TX = bytes32(uint256(1));

    // The list of transactions
    mapping(bytes32 => bytes32) internal txs;

    // The hash of the server
    bytes32 private serverHash;

    /**
     * @notice Initializes the contract with the chain id, genesis address and server hash
     * @param _chainId The chain id of the chain to index
     * @param _genesis The address of the genesis
     * @param _serverHash The hash of the server
     */
    function setupIndexer(
        uint256 _chainId,
        address _genesis,
        bytes32 _serverHash
    ) external {
        require(chainId == 0, "Indexer : Already initialized");
        txs[SENTINEL_TX] = SENTINEL_TX;
        GENESIS_ADDRESS = _genesis;
        chainId = _chainId;
        serverHash = _serverHash;
    }

    // Modifier to check if the contract is initialized
    modifier Initialized() {
        require(chainId != 0, "Indexer : Not initialized");
        _;
    }

    // Modifier to check if the caller is the genesis address
    modifier onlyGenesis() {
        require(msg.sender == GENESIS_ADDRESS, "Indexer : Not genesis");
        _;
    }

    /**
     *  @notice Returns the server hash
     */
    function getServerHash() external view returns (bytes32) {
        return serverHash;
    }

    /**
     * @notice Adds a transaction to the list
     * @param _tx The transaction to be added
     */
    function addTx(bytes32 _tx) external Initialized onlyGenesis {
        require(txs[_tx] == bytes32(uint256(0)), "Indexer : Invalid TxHash");

        require(_tx != SENTINEL_TX, "Indexer : Invalid TxHash");

        txs[_tx] = txs[SENTINEL_TX];
        txs[SENTINEL_TX] = _tx;
    }

    /**
     * @notice Checks if the transaction is a duplicate
     * @param _tx The transaction to be checked
     */
    function isTxDuplicate(bytes32 _tx) external view returns (bool) {
        return SENTINEL_TX != _tx && txs[_tx] != bytes32(uint256(0));
    }
}
