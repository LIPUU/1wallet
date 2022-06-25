// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.14;
interface I1wallet {
    struct Signature {
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    function executeEther(Signature[] calldata signatures, address target,uint256 amount, bytes calldata data) external;
    function EXECUTE_ETHER_HASH() external returns(bytes32);

    function executeERC20(Signature[] calldata signatures, address target,uint256 amount) external;
    function EXECUTE_ERC20_HASH() external returns(bytes32);

    function setQuorum(Signature[] calldata, uint256 Quorum) external;
    function QUORUM_HASH() external returns(bytes32);

    function setTrustedAddress(Signature[] calldata,address) external;
    function TRUSTED_ADDRESS_HASH() external returns(bytes32);


}