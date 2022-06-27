pragma solidity ^0.8.14;
import "forge-std/Test.sol";
import "../src/1wallet.sol";
import "forge-std/console.sol";
import "./unit.sol";
import "../src/1walletRouter.sol";

contract RouterTest is Test,OffChainSignHelper{
            /// ERROR ///

    error InitSignerInvalid();
    error InitQuorumBiggerThanSigners();
    error InitQuorumIs0();

    error InvalidNewQuorum();
    error InvalidSetTrustedAddress();

            /// EVENT ///
    event CreateNewWallet(address);
    event QuorumUpdated(uint256 );
    event TrustedAddressUpdated(address,bool);

    Router router;

    function setUp() public {
        for (uint256 i=0; i<privateKeys.length; ++i) {
            signers[i] = vm.addr(privateKeys[i]);
        }
    }

    function testCreateNewWallet() public {
        router = new Router(); 

    /// @dev 由于CreateNewWallet除了topic0之外没有topic是indexed，因此所有数据都被存放在data区域中了
    /// @dev 所以最后一个设置为false表明不对新得到的钱包地址进行检查
        vm.expectEmit(false,false,false,false);
        emit CreateNewWallet(address(0));

        router.createWallet("A",signers,signers.length);
    }

     /// @dev 测试signer重复的情况能否正确处理
    function testCreateNewWallet_Cannot_with_duplicate_signers() public {
        router = new Router(); 
        
        address tmp=signers[3];
        signers[3]=signers[4];
        signers[4]=tmp;

        vm.expectRevert(abi.encodeWithSignature('InitSignerInvalid()'));
        router.createWallet("A",signers,signers.length);
    }

     /// @dev 测试signer不按升序传参的情况能否正确处理
    function testCreateNewWallet_Cannot_outOfOrder() public {
        router = new Router(); 

        address tmp=signers[3];
        signers[3]=signers[0];
        signers[0]=tmp;

        vm.expectRevert(abi.encodeWithSignature('InitSignerInvalid()'));
        router.createWallet("A",signers,signers.length);
    }

     /// @dev 测试quorum大于signers数量的情况能否正确处理
    function testCreateNewWallet_quorum_Cannot_BiggerThanSigners() public {
        router = new Router(); 

        vm.expectRevert(abi.encodeWithSignature('InitQuorumBiggerThanSigners()'));
        router.createWallet("A",signers,signers.length+1);
    }

     /// @dev 测试quorum为0的情况能否正确处理
    function testCreateNewWallet_quorum_Cannot_beZer0() public {
        router = new Router(); 

        vm.expectRevert(abi.encodeWithSignature('InitQuorumIs0()'));
        router.createWallet("A",signers,0);
    }

    /// @dev 测试能够设置新Quorum
    function testCanSetQuorum() public {
        router = new Router();
        wallet = Wallet(payable(router.createWallet("A",signers,signers.length)));
        
        Wallet.Signature[] memory signatures=new Wallet.Signature[](signers.length);

        for(uint256 i=0;i<signatures.length;++i){
            signatures[i] = setQuorumSign(privateKeys[i],2);
        }
        
        vm.expectEmit(false,false,false,true);
        emit QuorumUpdated(2);

        router.setNewQuorum(wallet,signatures,2);
    }

    /// @dev 测试在设置新Quorum时能否处理新Quorum等于0或大于当前signer数量的异常情况
    function testSetNewQuorum_Cannot_BeZero_or_BiggerThanSigners() public {
        router = new Router();
        wallet = Wallet(payable(router.createWallet("A",signers,signers.length)));
        
        Wallet.Signature[] memory signatures=new Wallet.Signature[](signers.length);

        
        for(uint256 i=0;i<signatures.length;++i){
            signatures[i] = setQuorumSign(privateKeys[i],0);
        }
        vm.expectRevert(abi.encodeWithSignature('InvalidNewQuorum()'));
        router.setNewQuorum(wallet,signatures,0);

        
        for(uint256 i=0;i<signatures.length;++i){
            signatures[i] = setQuorumSign(privateKeys[i],signers.length+1);
        }
        vm.expectRevert(abi.encodeWithSignature('InvalidNewQuorum()'));
        router.setNewQuorum(wallet,signatures,signers.length+1);
    }

    /// @dev 测试能够正常设置signer为信任及不信任
    function testSetTrustedAddress() public {
        address newAddr=0x659f05D66Ba73b281B97A01aD21918e4475d20fE;

        router = new Router();
        wallet = Wallet(payable(router.createWallet("A",signers,signers.length)));
        
        Wallet.Signature[] memory signatures=new Wallet.Signature[](signers.length);

        for(uint256 i=0;i<signatures.length;++i){
            signatures[i] = setTrustedAddressSign(privateKeys[i],newAddr,true);
        }        
        vm.expectEmit(false,false,false,false);
        emit TrustedAddressUpdated(newAddr,true);

        router.setTrustedAddress(wallet,signatures,newAddr,true);
    }


    /// @dev 测试是否能处理trusted signers数量小于quorum的异常情况
    function testSetTrustedAddress_Cannot_SmallerThanQuorum() public {
        address alreadBeSigner=0xF6316684c0846505Be437d97D7ff86cB7d6bd34b;

        router = new Router();
        wallet = Wallet(payable(router.createWallet("A",signers,signers.length)));
        
        Wallet.Signature[] memory signatures=new Wallet.Signature[](signers.length);

        for(uint256 i=0;i<signatures.length;++i){
            signatures[i] = setTrustedAddressSign(privateKeys[i],alreadBeSigner,false);
        }        
        
        vm.expectRevert(abi.encodeWithSignature('InvalidSetTrustedAddress()'));
        router.setTrustedAddress(wallet,signatures,alreadBeSigner,false);
    }

    /// @dev 测试一个整体流程。我感觉可以用Echidna测试
    
    
}