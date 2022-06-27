// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.14;
import "./1wallet.sol";
import "forge-std/console.sol";

/// @dev router没有权限动用客户钱包里的资产。
/// @dev router中对客户数据做了一些校验，以避免在钱包合约中做校验从而增大钱包合约的尺寸
contract Router {
/// @dev 每个钱包地址的signer数量
/// @dev 该数量会随钱包初始化的时候初始化，并可能随着trusted addresses的更新而更新
    mapping(address=>uint256) public record;
                /// ERROR ///

    error InitSignerInvalid();
    error InitQuorumBiggerThanSigners();
    error InitQuorumIs0();
    
    error InvalidNewQuorum();
    error InvalidSetTrustedAddress();
                /// EVENT ///

    event CreateNewWallet(address);
    

/// @dev signers参数需要地址按升序排列
    function createWallet(
        string memory name,
        address[] memory signers,
        uint256 quorum
    ) public returns(address) {
        if (quorum>signers.length) revert InitQuorumBiggerThanSigners();
        if (quorum==0) revert InitQuorumIs0();

        address previous;
        for(uint i=0; i<signers.length; ++i){
            if(previous >= signers[i]) revert InitSignerInvalid();
            previous = signers[i];
        }

        address newWalletAddr = address(new Wallet(name,signers,quorum));
        emit CreateNewWallet(newWalletAddr);

        record[newWalletAddr]=signers.length;
        
        return newWalletAddr;
    }

/// @dev 钱包设置新Quorum时，新Quorum数量不能等于0,也不能大于当前signer的数量。合法性通过之后钱包合约仅需判断签名合法性即可
    function setNewQuorum(
        Wallet wallet,
        Wallet.Signature[] memory signatures,
        uint256 quorum
    ) public {
        if (quorum<1 || quorum>record[address(wallet)])
            revert InvalidNewQuorum();
        
        wallet.setQuorum(signatures,quorum);
    }


/// @dev 测试能够正常设置地址为信任及不信任。同时更新维护在本合约中的mapping及信任的signer地址数量。
/// @dev 如果在设置前后，某个地址的trusted性质变了，那么就要更新信任signer的地址数量.并保证当前信任的signers数量不能小于quorum
    function setTrustedAddress(
        Wallet wallet,
        Wallet.Signature[] memory signatures,
        address signer,
        bool trusted
    ) public {
        if (wallet.trusted(signer)!=trusted){
            if(trusted) 
                ++record[address(wallet)];
            else{
                console.log(record[signer]);
                if (wallet.quorum() > --record[address(wallet)]) {
                    revert InvalidSetTrustedAddress();
                }
            }
        }

        wallet.setTrustedAddress(signatures,signer,trusted);
    }

}