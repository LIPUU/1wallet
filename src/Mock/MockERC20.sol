// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.14;
import "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

contract MyToken is ERC20 {
    constructor(uint256 initialSupply) ERC20("MYTOKEN","MTK"){
        _mint(msg.sender,initialSupply);
    }
}