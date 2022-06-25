// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.14;
import "forge-std/console.sol";

contract Wallet {
    /// ERRORS ///
    error InvaildSignatures();
    error ExecutionFailed();

    /// EVENT ///
    event Executed(address target, uint256 amount,bytes data);

    string name;
    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;
    uint256 internal immutable INITIAL_CHAIN_ID;
    uint256 public nonce;

    bytes32 public constant EXECUTE_ETHER_HASH=
        keccak256("ExecuteEther(address target,uint256 amount,bytes data,uint256 nonce)");

    bytes32 public constant EXECUTE_ERC20_HASH=
        keccak256("ExecuteERC20(address target,uint256 amount,uint256 nonce)");

    bytes32 public constant QUORUM_HASH=
        keccak256("SetQuorum(uint256 newQuorum,uint256 nonce)");
    
    bytes32 public constant TRUSTED_ADDRESS_HASH=
        keccak256("setTrustedAddress(address addr,uint256 nonce)");

    uint256 quorum;
    mapping(address=>bool) trusted;

    receive() external payable {}

//  @dev 没有做对重复地址 & _quorum大于signers.length的异常校验。这两个应该交给路由合约或前端
    constructor(
        string memory _name,
        address[] memory signers,
        uint256 _quorum
    ) payable {
        name=_name;
        quorum = _quorum;

        nonce=1;
        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = calculateDomainSeparator();
        
        unchecked {
            for (uint256 i=0;i<signers.length;++i) {
                trusted[signers[i]]=true;
            }
        }
    }

    function executeEther(Signature[] calldata signatures, address target,uint256 amount, bytes calldata data) external {
        bytes32 digest = keccak256( // 这个是digest
				abi.encodePacked(
					'\x19\x01',
					domainSeparator(),
					keccak256(
						abi.encode(
							EXECUTE_ETHER_HASH,
							target,
							amount,
							data,
							nonce++
						)
					)
				)
			);
        
        address previous;
        unchecked {
            for (uint256 i=0; i<quorum; ++i ) {
                address signer=ecrecover(digest,signatures[i].v, signatures[i].r, signatures[i].s);

                if (!trusted[signer] || previous >= signer)
                    revert InvaildSignatures();
                
                previous = signer;
            }
        }

        (bool successful,)=target.call{value:amount}(data);
        if (!successful) revert ExecutionFailed();

        emit Executed(target,amount,data);
    }

    function executeERC20(Signature[] calldata signatures, address target,uint256 amount) external {

    }

    function setQuorum(Signature[] calldata signatures, uint256 quorum) external {

    }

    function setTrustedAddress(Signature[] calldata signatures,address addr) external {

    }

    function domainSeparator()  public view returns (bytes32) {
        return INITIAL_CHAIN_ID == block.chainid ? INITIAL_DOMAIN_SEPARATOR : calculateDomainSeparator();
    }

    function calculateDomainSeparator() view internal returns(bytes32){
        return keccak256(
                abi.encode(
                    keccak256(
                        'EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'
                    ),
                    keccak256(bytes(name)),
                    keccak256(bytes('1')),
                    block.chainid,
                    address(this)
                )
            );
    }
    

    struct Signature {
        uint8 v;
        bytes32 r;
        bytes32 s;
    }


}