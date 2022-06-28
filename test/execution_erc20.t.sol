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

/// @dev 检查可以提款0个token
    function testExecuteERC20_With_0Token() public {
        wallet = new Wallet("w",signers,signers.length);

        Wallet.Signature[] memory signatures=new Wallet.Signature[](signers.length);

        for(uint256 i=0;i<signatures.length;++i){
            signatures[i] = executionERC20Sign(privateKeys[i],address(myToken),targetAddress,0);
        }

    /// @dev 检查from，to，这两个是indexed的; 不检查amount，因为它不是indexed，但它被附加在了data字段，因此仍然可以做相应的检查
    /// @dev 并检查该Event的发起者是myToken合约
        vm.expectEmit(true,true,false,true,address(myToken));
        emit Transfer(address(wallet), targetAddress, 0);
        
        wallet.executeERC20(signatures,address(myToken),address(targetAddress),0);
        
        assertEq(myToken.balanceOf(address(targetAddress)),0);
        assertEq(wallet.nonce(),2);
    }

/// @dev 检查可以提款一定数量的token
    function testExecuteERC20_With_SomeToken() public {
        wallet = new Wallet("w",signers,signers.length);
        myToken.transfer(address(wallet),10);

        Wallet.Signature[] memory signatures=new Wallet.Signature[](signers.length);

        for(uint256 i=0;i<signatures.length;++i){
            signatures[i] = executionERC20Sign(privateKeys[i],address(myToken),targetAddress,6);
        }

        vm.expectEmit(true,true,false,true,address(myToken));
        emit Transfer(address(wallet), targetAddress, 6);
        
        wallet.executeERC20(signatures,address(myToken),address(targetAddress),6);
        
        assertEq(myToken.balanceOf(address(this)),90);
        assertEq(myToken.balanceOf(targetAddress),6);
        assertEq(myToken.balanceOf(address(wallet)),4);
        assertEq(wallet.nonce(),2);
    }


/// @dev fuzzer，检查可以提取不超过钱包中存放资产数量的token
/// @dev 由于fuzzer的不确定性，因此参数具体是哪一个将在测试函数内进行检查
    function testExecuteERC20_With_FuzzerToken(uint256 a,uint256 b) public {
    /// @dev address(this)拥有的token数量，固定为100000
        uint256 tokenTotal=100000;

        uint256 walletTotal;
        uint256 withdrawAmount;

        if (a>b)
            (walletTotal,withdrawAmount)=(a,b);
        else
            (walletTotal,withdrawAmount)=(b,a);

        uint256 realWithDrawAmount = withdrawAmount % tokenTotal;
        uint256 realWalletTotal = walletTotal % tokenTotal;

        if (realWalletTotal < realWithDrawAmount)
            (realWalletTotal,realWithDrawAmount)=(realWithDrawAmount,realWalletTotal);

        IERC20 t=IERC20(new MyToken(tokenTotal));

        wallet = new Wallet("w",signers,signers.length);

        t.transfer(address(wallet), realWalletTotal);
        
        Wallet.Signature[] memory signatures=new Wallet.Signature[](signers.length);

        for(uint256 i=0; i<signatures.length; ++i) {
            signatures[i] = executionERC20Sign(privateKeys[i],address(t),targetAddress,realWithDrawAmount);
        }

        vm.expectEmit(true,true,false,true,address(t));
        emit Transfer(address(wallet), targetAddress, realWithDrawAmount);
        
        wallet.executeERC20(signatures,address(t),address(targetAddress),realWithDrawAmount);
        
        assertEq(t.balanceOf(address(this)),tokenTotal-realWalletTotal);
        
        assertEq(t.balanceOf(targetAddress),realWithDrawAmount);
        assertEq(t.balanceOf(address(wallet)),realWalletTotal-realWithDrawAmount);
        assertEq(wallet.nonce(),2);
    }

    function testExecuteERC20_Cannot_With_WrongTokenAmount() public {
        wallet = new Wallet("w",signers,signers.length);
        myToken.transfer(address(wallet),10);

        Wallet.Signature[] memory signatures=new Wallet.Signature[](signers.length);

        for(uint256 i=0;i<signatures.length;++i){
            signatures[i] = executionERC20Sign(privateKeys[i],address(myToken),targetAddress,11);
        }

        
        vm.expectRevert(abi.encodeWithSignature('ExecutionFailed()'));
        wallet.executeERC20(signatures,address(myToken),address(targetAddress),11);
    }

    function testExecuteERC20_ManyTimes_WithDraw() public {
        wallet = new Wallet("w",signers,signers.length);
        myToken.transfer(address(wallet),10);

        Wallet.Signature[] memory signatures=new Wallet.Signature[](signers.length);

        for(uint256 i=0;i<signatures.length;++i){
            signatures[i] = executionERC20Sign(privateKeys[i],address(myToken),targetAddress,6);
        }

        vm.expectEmit(true,true,false,true,address(myToken));
        emit Transfer(address(wallet), targetAddress, 6);
        
        wallet.executeERC20(signatures,address(myToken),address(targetAddress),6);

    /// @dev twice transfer
        for(uint256 i=0;i<signatures.length;++i){
            signatures[i] = executionERC20Sign(privateKeys[i],address(myToken),targetAddress,2);
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