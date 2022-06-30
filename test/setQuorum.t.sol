// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.14;
import "forge-std/Test.sol";
import "../src/1wallet.sol";
import "forge-std/console.sol";
import "./unit.sol";

contract setNewQuorum is Test,OffChainSignHelper {
    event QuorumUpdated(uint256 newQuorum);

    function setUp() public {
        for (uint256 i=0; i<privateKeys.length; ++i) {
            signers[i] = vm.addr(privateKeys[i]);
        }
    }

    function testSetNewQuorum() public {
        wallet = new Wallet("w",signers,signers.length);
        
        Wallet.Signature[] memory signatures=new Wallet.Signature[](signers.length);

        for(uint256 i=0;i<signatures.length;++i){
            signatures[i] = setQuorumSign(privateKeys[i],2);
        }

        vm.expectEmit(false,false,false,true);
        emit QuorumUpdated(2);
        
        wallet.setQuorum(signatures,2);
        
    }
}
