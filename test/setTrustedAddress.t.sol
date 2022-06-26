// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.14;
import "forge-std/Test.sol";
import "../src/1wallet.sol";
import "forge-std/console.sol";
import "./unit.sol";

contract setTrustedAddress is Test,OffChainSignHelper {
    event TrustedAddressUpdated(address,bool);
    address addr=0x659f05D66Ba73b281B97A01aD21918e4475d20fE;
    function setUp() public {
        for (uint256 i=0; i<privateKeys.length; ++i) {
            signers[i] = vm.addr(privateKeys[i]);
        }
    }

    function testCanSetTrustedAddress() public {
        wallet = new Wallet("w",signers,signers.length);
        
        Wallet.Signature[] memory signatures=new Wallet.Signature[](signers.length);

    /// @dev set trusted signer
        for(uint256 i=0;i<signatures.length;++i){
            signatures[i] = setTrustedAddressSign(privateKeys[i],addr,true);
        }

        vm.expectEmit(false,false,false,true);
        emit TrustedAddressUpdated(addr,true);

        wallet.setTrustedAddress(signatures,addr,true);

    /// @dev set untrusted signer
        for(uint256 i=0;i<signatures.length;++i){
            signatures[i] = setTrustedAddressSign(privateKeys[i],addr,false);
        }

        vm.expectEmit(false,false,false,true);
        emit TrustedAddressUpdated(addr,false);

        wallet.setTrustedAddress(signatures,addr,false);
    }

    function testCannotSet0Address() public {
        wallet = new Wallet("w",signers,signers.length);
        
        Wallet.Signature[] memory signatures=new Wallet.Signature[](signers.length);

    /// @dev set trusted signer
        for(uint256 i=0;i<signatures.length;++i){
            signatures[i] = setTrustedAddressSign(privateKeys[i],address(0),true);
        }

        vm.expectRevert(abi.encodeWithSignature("ExecutionFailed()"));
        wallet.setTrustedAddress(signatures,address(0),true);
    }
}