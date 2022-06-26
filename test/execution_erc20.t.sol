// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.14;
import "forge-std/Test.sol";
import "../src/1wallet.sol";
import "forge-std/console.sol";
import "./unit.sol";
import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "../src/Mock/MockERC20.sol";

contract ExecutionERC20Test is Test,OffChainSignHelper {
    IERC20 myToken;

    address targetAddress=0x659f05D66Ba73b281B97A01aD21918e4475d20fE;

    event Transfer(address indexed from, address indexed to, uint256 value);
    
    function setUp() public {
        myToken=IERC20(new MyToken(100));

        for (uint256 i=0; i<privateKeys.length; ++i) {
            signers[i] = vm.addr(privateKeys[i]);
        }
        
    }

    function testExecuteERC20_With_0Token() public {
        wallet = new Wallet("w",signers,signers.length);

        Wallet.Signature[] memory signatures=new Wallet.Signature[](signers.length);

        for(uint256 i=0;i<signatures.length;++i){
            signatures[i] = executionEtherERC20Sign(privateKeys[i],address(myToken),targetAddress,0);
        }

    /// @dev 检查from，to，这两个是indexed的; 不检查amount，因为它不是indexed，但它被附加在了data字段，因此仍然可以做相应的检查
    /// @dev 并检查该Event的发起者是myToken合约
        vm.expectEmit(true,true,false,true,address(myToken));
        emit Transfer(address(wallet), targetAddress, 0);
        
        wallet.executeERC20(signatures,address(myToken),address(targetAddress),0);
        
        assertEq(myToken.balanceOf(address(targetAddress)),0);
        assertEq(wallet.nonce(),2);
    }

    function testExecuteERC20_With_SomeToken() public {
        wallet = new Wallet("w",signers,signers.length);
        myToken.transfer(address(wallet),10);

        Wallet.Signature[] memory signatures=new Wallet.Signature[](signers.length);

        for(uint256 i=0;i<signatures.length;++i){
            signatures[i] = executionEtherERC20Sign(privateKeys[i],address(myToken),targetAddress,6);
        }

    /// @dev 检查from，to，这两个是indexed的; 不检查amount，因为它不是indexed，但它被附加在了data字段，因此仍然可以做相应的检查
    /// @dev 并检查该Event的发起者是myToken合约
        vm.expectEmit(true,true,false,true,address(myToken));
        emit Transfer(address(wallet), targetAddress, 6);
        
        wallet.executeERC20(signatures,address(myToken),address(targetAddress),6);
        
        assertEq(myToken.balanceOf(address(this)),90);
        assertEq(myToken.balanceOf(targetAddress),6);
        assertEq(myToken.balanceOf(address(wallet)),4);
        assertEq(wallet.nonce(),2);
    }

    function testExecuteERC20_Cannot_With_WrongTokenAmount() public {
        wallet = new Wallet("w",signers,signers.length);
        myToken.transfer(address(wallet),10);

        Wallet.Signature[] memory signatures=new Wallet.Signature[](signers.length);

        for(uint256 i=0;i<signatures.length;++i){
            signatures[i] = executionEtherERC20Sign(privateKeys[i],address(myToken),targetAddress,11);
        }

        
        vm.expectRevert(abi.encodeWithSignature('ExecutionFailed()'));
        wallet.executeERC20(signatures,address(myToken),address(targetAddress),11);
    }

    function testExecuteERC20_ManyTimes_WithDraw() public {
        wallet = new Wallet("w",signers,signers.length);
        myToken.transfer(address(wallet),10);

        Wallet.Signature[] memory signatures=new Wallet.Signature[](signers.length);

        for(uint256 i=0;i<signatures.length;++i){
            signatures[i] = executionEtherERC20Sign(privateKeys[i],address(myToken),targetAddress,6);
        }

        vm.expectEmit(true,true,false,true,address(myToken));
        emit Transfer(address(wallet), targetAddress, 6);
        
        wallet.executeERC20(signatures,address(myToken),address(targetAddress),6);

    /// @dev twice transfer
        for(uint256 i=0;i<signatures.length;++i){
            signatures[i] = executionEtherERC20Sign(privateKeys[i],address(myToken),targetAddress,2);
        }

        vm.expectEmit(true,true,false,true,address(myToken));
        emit Transfer(address(wallet), targetAddress, 2);
        
        wallet.executeERC20(signatures,address(myToken),address(targetAddress),2);
        
        assertEq(myToken.balanceOf(address(this)),90);
        assertEq(myToken.balanceOf(targetAddress),8);
        assertEq(myToken.balanceOf(address(wallet)),2);
        assertEq(wallet.nonce(),3);
    }

    /// @dev 由于签名验证部分的实现和ExecutionEther完全一样,因此关于签名验证部分的异常测试可以省略    
}