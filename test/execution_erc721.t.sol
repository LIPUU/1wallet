// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.14;
import "forge-std/Test.sol";
import "../src/1wallet.sol";
import "forge-std/console.sol";
import "./unit.sol";
import "../src/Mock/MockERC721.sol";
import "openzeppelin-contracts/contracts/utils/introspection/ERC165.sol";

/// @notice a NFT manager
contract CanReceiveNTF {
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external virtual returns (bytes4) {
        // or directly return 0x150b7a02
        return ERC721TokenReceiver.onERC721Received.selector;
    }

    function mockManageERC721Token() public view {}
}

contract ExecutionERC721Test is Test,OffChainSignHelper {
    /// EVENT ///
    event Transfer(address indexed from, address indexed to, uint256 indexed id);
    /// ERROR ///

    MockNFT myNFT;
    CanReceiveNTF canReceiveNTF;
    address nftOwner=0xb1FE3469d488779bd974841C316D66c447EA4c7F;
    address toEOAaddress=0x659f05D66Ba73b281B97A01aD21918e4475d20fE;
    
    function setUp() public {
        myNFT=new MockNFT("A","A","ipfs://");

        for (uint256 i=0; i<privateKeys.length; ++i) {
            signers[i] = vm.addr(privateKeys[i]);
        }
        /// ? 需要这样给address(this)设置ether吗
        /// address(this)是否有ether
        vm.deal(address(this),10 ether);
        
        /// 需要以这种方式给gas费吗？？？
        vm.deal(nftOwner,10 ether);
    }

    /// @notice 检查可以将NFT从钱包转至toEOAaddress
    function testTransferNFTtoEOA() public {
        wallet = new Wallet("w",signers,signers.length);
        Wallet.Signature[] memory signatures=new Wallet.Signature[](signers.length);
        
        uint256 id=myNFT.mintTo{value:0.08 ether}(nftOwner);
        assertEq(myNFT.ownerOf(id),nftOwner);

        vm.prank(nftOwner);
        vm.expectEmit(true,true,true,true,address(myNFT));
        emit Transfer(nftOwner, address(wallet),id);

        myNFT.safeTransferFrom(nftOwner,address(wallet),id);
        assertEq(myNFT.ownerOf(id),address(wallet));

        for(uint256 i=0;i<signatures.length;++i) {
            signatures[i] = ExecutionERC721Sign(privateKeys[i],address(myNFT),address(wallet),toEOAaddress,id);
        }

        vm.expectEmit(true,true,true,true,address(myNFT));
        emit Transfer(address(wallet), toEOAaddress,id);
        wallet.executeNFT(signatures,address(myNFT),address(wallet),toEOAaddress,id);

        assertEq(myNFT.ownerOf(id),toEOAaddress);
    }

    /// @notice 检查可以将NFT转至具有管理功能的CanReceiveNTF合约
    function testCanTransferNFTtoNftManager() public {
        canReceiveNTF=new CanReceiveNTF();
        wallet = new Wallet("w",signers,signers.length);
        Wallet.Signature[] memory signatures=new Wallet.Signature[](signers.length);
        
        uint256 id=myNFT.mintTo{value:0.08 ether}(nftOwner);
        assertEq(myNFT.ownerOf(id),nftOwner);

        vm.prank(nftOwner);
        vm.expectEmit(true,true,true,true,address(myNFT));
        emit Transfer(nftOwner, address(wallet),id);

        myNFT.safeTransferFrom(nftOwner,address(wallet),id);
        assertEq(myNFT.ownerOf(id),address(wallet));

        for(uint256 i=0;i<signatures.length;++i) {
            signatures[i] = ExecutionERC721Sign(privateKeys[i],address(myNFT),address(wallet),address(canReceiveNTF),id);
        }

        vm.expectEmit(true,true,true,true,address(myNFT));
        emit Transfer(address(wallet), address(canReceiveNTF),id);
        wallet.executeNFT(signatures,address(myNFT),address(wallet),address(canReceiveNTF),id);

        assertEq(myNFT.ownerOf(id),address(canReceiveNTF));

    }

    /// @notice 检查不能将NFT转至不具有管理功能的合约
    function testFail_CannotTransferNFTtoNonNftManager() public {
        vm.etch(address(1), bytes("mock code"));

        wallet = new Wallet("w",signers,signers.length);
        Wallet.Signature[] memory signatures=new Wallet.Signature[](signers.length);
        
        uint256 id=myNFT.mintTo{value:0.08 ether}(nftOwner);
        assertEq(myNFT.ownerOf(id),nftOwner);

        vm.prank(nftOwner);
        vm.expectEmit(true,true,true,true,address(myNFT));
        emit Transfer(nftOwner, address(wallet),id);
        myNFT.safeTransferFrom(nftOwner,address(wallet),id);
        assertEq(myNFT.ownerOf(id),address(wallet));

        for(uint256 i=0; i<signatures.length; ++i) {
            signatures[i] = ExecutionERC721Sign(privateKeys[i],address(myNFT),address(wallet),address(1),id);
        }

        wallet.executeNFT(signatures,address(myNFT),address(wallet),address(1),id);
    }
}
