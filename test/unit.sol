// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.14;
import "../src/1wallet.sol";
import "forge-std/Test.sol";

contract TargetAddress {
/// @notice 钱包取款时如果使用call调用的方式，该变量强行使fallback执行失败
    bool  force_revert;
    function set_force_revert(bool _force_revert) public {
        force_revert=_force_revert;
    }

    receive() external payable {}
    fallback() external payable{
        if (force_revert) {
            revert();
        }
    }
}

/// @dev 模拟用户在链下签名的工具合约，编写测试时使用
/// @dev 正常情况下用户在链下由其他编程语言生成签名
abstract contract OffChainSignHelper {
/// @dev 继承OffChainSignHelper的测试合约将在每个测试函数中生成各自的walle合约实例
    Wallet internal wallet;
    Vm internal hevm=Vm(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);
    
/// @dev 这几个私钥生成的地址是升序的
    uint256[] internal privateKeys=[0xBEEF, 0xBEEE, 0x1234, 0x3221, 0x0010, 0x0100, 0x0323];
    address[] internal signers = new address[](privateKeys.length);

/// @notice 用户进行Ether提款操作时的签名工具
/// @param signer 签名者的私钥
/// @param target Ether的接收帐户
/// @param amount 提款Ether的数量
/// @param data 执行操作时将在target上使用该参数调用call
/// @return 用私钥和上述三个参数进行签名操作得到的签名数据
    function executionEtherSign (
        uint256 signer,
        address target,
        uint256 amount,
        bytes memory data
        ) public returns(Wallet.Signature memory){
            (uint8 v,bytes32 r, bytes32 s) = hevm.sign(
                signer,
                keccak256( // 这个是digest. 链上链下计算digest的步骤是完全一样的
				abi.encodePacked(
					'\x19\x01',
					wallet.domainSeparator(),
					keccak256(
						abi.encode(
							wallet.EXECUTE_ETHER_HASH(),
							target,
							amount,
							data,
							wallet.nonce()
						)
					)
				)
			)
        );
        return Wallet.Signature(v,r,s);
    }

/// @notice 用户进行ERC20代币提款操作时的签名工具
    function executionERC20Sign (
        uint256 signer,
        address erc20Token,
        address target,
        uint256 amount
        ) public returns(Wallet.Signature memory){
            (uint8 v,bytes32 r, bytes32 s) = hevm.sign(
                signer,
                keccak256( // 这个是digest
				abi.encodePacked(
					'\x19\x01',
					wallet.domainSeparator(),
					keccak256(
						abi.encode(
							wallet.EXECUTE_ERC20_HASH(),
                            				erc20Token,
							target,
							amount,
							wallet.nonce()
						)
					)
				)
			)
        );
        return Wallet.Signature(v,r,s);
    }

/// @notice 用户转移NFT时的签名工具
    function ExecutionERC721Sign (
        uint256 signer,
        address erc721Token,
        address from,
        address to,
        uint256 nftID 
    ) public returns(Wallet.Signature memory) {
        (uint8 v,bytes32 r, bytes32 s) = hevm.sign(
                signer,
                keccak256( // 这个是digest
				abi.encodePacked(
					'\x19\x01',
					wallet.domainSeparator(),
					keccak256(
						abi.encode(
							wallet.EXECUTE_ERC721_HASH(),
                            				erc721Token,
                            				from,
							to,
							nftID,
							wallet.nonce()
						)
					)
				)
			)
        );
        return Wallet.Signature(v,r,s);
    }

/// @notice 用户设置新Quorum数量时的签名工具
    function setQuorumSign (
        uint256 signer,
        uint256 newQuorum
        ) public returns(Wallet.Signature memory){
            (uint8 v,bytes32 r, bytes32 s) = hevm.sign(
                signer,
                keccak256( // 这个是digest
				abi.encodePacked(
					'\x19\x01',
					wallet.domainSeparator(),
					keccak256(
						abi.encode(
							wallet.QUORUM_HASH(),
							newQuorum,
							wallet.nonce()
						)
					)
				)
			)
        );
        return Wallet.Signature(v,r,s);
    }

/// @notice 用户设置信任或不信任某个地址时的签名工具
    function setTrustedAddressSign (
        uint256 signer,
        address addr,
        bool trusted_or_not
        ) public returns(Wallet.Signature memory){
            (uint8 v,bytes32 r, bytes32 s) = hevm.sign(
                signer,
                keccak256( // 这个是digest
				abi.encodePacked(
					'\x19\x01',
					wallet.domainSeparator(),
					keccak256(
						abi.encode(
							wallet.TRUSTED_ADDRESS_HASH(),
                            				addr,
                            				trusted_or_not,
							wallet.nonce()
						)
					)
				)
			)
        );
        return Wallet.Signature(v,r,s);
    }
}
