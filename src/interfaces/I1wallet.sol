// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.14;
interface I1wallet {
    struct Signature {
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    function setQuorum(Signature[] calldata, uint256 Quorum) external;

    function setTrustedAddress(Signature[] calldata,address) external;

    function trusted(address) external returns (bool) ;
}