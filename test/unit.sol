// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.14;
import "../src/1wallet.sol";
import "forge-std/Test.sol";

contract TargetAddress {
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

abstract contract OffChainSignHelper {
    Wallet internal wallet; // 在该合约的子合约中对wallet进行初始化
    Vm internal hevm=Vm(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);
    uint256[] internal privateKeys=[0xBEEF, 0xBEEE, 0x1234, 0x3221, 0x0010, 0x0100, 0x0323];
    address[] internal signers = new address[](privateKeys.length);
    function executionEtherSign (
        uint256 signer,
        address target,
        uint256 amount,
        bytes memory data
        ) public returns(Wallet.Signature memory){
            (uint8 v,bytes32 r, bytes32 s) = hevm.sign(
                signer,
                keccak256( // 这个是digest
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

    function executionEtherERC20Sign (
        uint256 signer,
        address token,
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
                            token,
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