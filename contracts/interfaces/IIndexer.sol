// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

interface IIndexer {
    function addTx(bytes32 _tx) external;

    function getServerHash() external view returns (bytes32);
}
