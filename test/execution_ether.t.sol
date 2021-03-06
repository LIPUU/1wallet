// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.14;
import "forge-std/Test.sol";
import "../src/1wallet.sol";
import "forge-std/console.sol";
import "./unit.sol";

contract ExecutionEtherTest is Test,OffChainSignHelper {

    TargetAddress targetAddress;     

    event Executed(address target, uint256 amount,bytes data);

    function setUp() public {
        targetAddress=new TargetAddress();
        for (uint256 i=0; i<privateKeys.length; ++i) {
            signers[i] = vm.addr(privateKeys[i]);
        }
    }

    function testExecuteEther_With_0Ether() public {
        wallet = new Wallet("w",signers,signers.length);
        
        Wallet.Signature[] memory signatures=new Wallet.Signature[](signers.length);
        for(uint256 i=0;i<signatures.length;++i){
            signatures[i] = executionEtherSign(privateKeys[i],address(targetAddress),0,'');
        }

        vm.expectEmit(false,false,false,true);
        emit Executed(address(targetAddress), 0, '');
        
        wallet.executeEther(signatures,address(targetAddress),0,'');
        
        assertEq(0,address(targetAddress).balance);
        assertEq(wallet.nonce(),2);
    }

    function testExecuteEther_With_SomeEther() public {
        wallet = new Wallet("w",signers,signers.length);
        vm.deal(address(wallet),10 ether);

        Wallet.Signature[] memory signatures=new Wallet.Signature[](signers.length);
        for(uint256 i=0;i<signatures.length;++i){
            signatures[i] = executionEtherSign(privateKeys[i],address(targetAddress),6 ether,'');
        }
        
        vm.expectEmit(false,false,false,true);
        emit Executed(address(targetAddress), 6 ether, '');

        wallet.executeEther(signatures,address(targetAddress),6 ether,'');
        
        assertEq(address(targetAddress).balance, 6 ether);
        assertEq(address(wallet).balance, 4 ether);
        assertEq(wallet.nonce(),2);
    }

    /// @dev 测试几种异常签名：1.执行时签名数量不满足quorum; 2.签名有重复; 3.调用函数时签名所对应的地址无序; 
    /// @dev                4.虚假签名(某个trusted address签署错误信息 / 使用untrusted address 签署信息)
    /// @dev 1会引发数组越界
    /// @dev 2、3、4属于error InvaildSignatures
    function testExecuteEther_Cannot_With_NotEnoughQuorum() public {
        wallet = new Wallet("w",signers,signers.length+1);
        vm.deal(address(wallet),10 ether);
        
        Wallet.Signature[] memory signatures=new Wallet.Signature[](signers.length);

        for(uint256 i=0;i<signatures.length;++i){
            signatures[i] = executionEtherSign(privateKeys[i],address(targetAddress),6 ether,'');
        }
        
        vm.expectRevert(stdError.indexOOBError);
        wallet.executeEther(signatures,address(targetAddress),6 ether,'');
    }

    function testExecuteEther_Cannot_With_DuplicateSignature() public {
        wallet = new Wallet("w",signers,signers.length);
        vm.deal(address(wallet),10 ether);

        Wallet.Signature[] memory signatures=new Wallet.Signature[](signers.length);
        

        for(uint256 i=0; i<signatures.length; ++i){
            signatures[i] = executionEtherSign(privateKeys[i],address(targetAddress),6 ether,'');
        }

        signatures[0]=signatures[1];

        vm.expectRevert(abi.encodeWithSignature('InvaildSignatures()'));
        wallet.executeEther(signatures,address(targetAddress),6 ether,'');
    }

    function testExecuteEther_Cannot_With_OutOfOrder_Signer() public {
        wallet = new Wallet("w",signers,signers.length);
        vm.deal(address(wallet),10 ether);
        
        Wallet.Signature[] memory signatures=new Wallet.Signature[](signers.length);

        for(uint256 i=0; i<signatures.length; ++i){
            signatures[i] = executionEtherSign(privateKeys[i],address(targetAddress),6 ether,'');
        }

        Wallet.Signature memory tmp=signatures[3];
        signatures[3]=signatures[0];
        signatures[0]=tmp;

        vm.expectRevert(abi.encodeWithSignature('InvaildSignatures()'));
        wallet.executeEther(signatures,address(targetAddress),6 ether,'');
    }
    
    function testExecuteEther_Cannot_with_WrongSignInformation() public {
        wallet = new Wallet("w",signers,signers.length);
        vm.deal(address(wallet),10 ether);
        
        Wallet.Signature[] memory signatures=new Wallet.Signature[](signers.length);

        for(uint256 i=0; i<signatures.length; ++i){
            signatures[i] = executionEtherSign(privateKeys[i],address(targetAddress),6 ether,'');
        }

        signatures[3] = executionEtherSign(privateKeys[3],address(targetAddress),1 ether,'');

        vm.expectRevert(abi.encodeWithSignature('InvaildSignatures()'));
        wallet.executeEther(signatures,address(targetAddress),6 ether,'');
    }
    
    function testExecuteEther_Cannot_with_WrongSigner() public {
        wallet = new Wallet("w",signers,signers.length);
        vm.deal(address(wallet),10 ether);
        
        Wallet.Signature[] memory signatures=new Wallet.Signature[](signers.length);

        for(uint256 i=0; i<signatures.length; ++i){
            signatures[i] = executionEtherSign(privateKeys[i],address(targetAddress),6 ether,'');
        }

        signatures[4] = executionEtherSign(0xDEAD,address(targetAddress),6 ether,'');

        vm.expectRevert(abi.encodeWithSignature('InvaildSignatures()'));
        wallet.executeEther(signatures,address(targetAddress),6 ether,'');
    }

    /// @dev 测试执行成功
    function testExecuteEther_with_data() public {
        wallet = new Wallet("w",signers,signers.length);
        vm.deal(address(wallet),10 ether);

        Wallet.Signature[] memory signatures=new Wallet.Signature[](signers.length);

        for(uint256 i=0; i<signatures.length; ++i){
            signatures[i] = executionEtherSign(privateKeys[i],address(targetAddress),6 ether,'heiheihei');
        }

        wallet.executeEther(signatures,address(targetAddress),6 ether,'heiheihei');

        assertEq(address(targetAddress).balance, 6 ether);
        assertEq(address(wallet).balance, 4 ether);
        assertEq(wallet.nonce(),2);
    }

    /// @dev 测试执行失败
    function testExecuteEther_Call_with_forge_revert() public {
        wallet = new Wallet("w",signers,signers.length);
        vm.deal(address(wallet),10 ether);

        Wallet.Signature[] memory signatures=new Wallet.Signature[](signers.length);

        for(uint256 i=0; i<signatures.length; ++i){
            signatures[i] = executionEtherSign(privateKeys[i],address(targetAddress),6 ether,'heiheihei');
        }
        
        targetAddress.set_force_revert(true);

        vm.expectRevert(abi.encodeWithSignature('ExecutionFailed()'));
        wallet.executeEther(signatures,address(targetAddress),6 ether,'heiheihei');
    }

    /// @dev 测试重放签名
    function test_Cannot_ReuseSignature() public {
        wallet = new Wallet("w",signers,signers.length);
        vm.deal(address(wallet),10 ether);

        Wallet.Signature[] memory signatures = new Wallet.Signature[](signers.length);

        for(uint256 i=0; i<signatures.length; ++i){
            signatures[i] = executionEtherSign(privateKeys[i],address(targetAddress),6 ether,'');
        }
        
        wallet.executeEther(signatures,address(targetAddress),6 ether,'');

        assertEq(address(targetAddress).balance, 6 ether);
        assertEq(address(wallet).balance, 4 ether);
        assertEq(wallet.nonce(),2);
        
        vm.expectRevert(abi.encodeWithSignature('InvaildSignatures()'));
        wallet.executeEther(signatures,address(targetAddress),1 ether,'');
    }

    /// @dev 测试在chainid更新之后，之前的签名不能被重用
    function test_Cannot_use_PreSignature_when_chainid_changed() public {
        wallet = new Wallet("w",signers,signers.length);
        vm.deal(address(wallet),10 ether);

        Wallet.Signature[] memory signatures = new Wallet.Signature[](signers.length);

        for(uint256 i=0; i<signatures.length; ++i){
            signatures[i] = executionEtherSign(privateKeys[i],address(targetAddress),6 ether,'');
        }

        vm.chainId(9999);
        

        vm.expectRevert(abi.encodeWithSignature('InvaildSignatures()'));
        wallet.executeEther(signatures,address(targetAddress),6 ether,'');
    }
}
