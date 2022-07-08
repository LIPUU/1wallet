// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.14;
import "forge-std/console.sol";
import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "solmate/tokens/ERC721.sol";

/// @dev domin separator能够在全区块链网络中(包括分叉链)唯一标识某个eip712实例
/// @dev FUNCTIONNAME_HASH能够唯一标识出用户想要执行的函数
/// @dev nonce保证了每个签名只能被执行一次

contract Wallet {
    /// ERRORS ///

    error InvaildSignatures();
    error ExecutionFailed();
    error SetNewQuorumFailed();

    /// EVENT ///
    event Executed(address , uint256 ,bytes );
    event QuorumUpdated(uint256 );
    event TrustedAddressUpdated(address,bool);

    string name;
    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;
    uint256 internal immutable INITIAL_CHAIN_ID;
    uint256 public nonce;

/// @dev 本合约中有四个需要结构化签名的函数，通过EXECUTE_ETHER_HASH能够唯一地标识出它们，并参与到digest中的计算中去

    bytes32 public constant EXECUTE_ETHER_HASH=
        keccak256("ExecuteEther(address target,uint256 amount,bytes data,uint256 nonce)");

    bytes32 public constant EXECUTE_ERC20_HASH=
        keccak256("ExecuteERC20(address token,address target,uint256 amount,uint256 nonce)");

    bytes32 public constant EXECUTE_ERC721_HASH=
        keccak256("ExecuteERC721(address token,address from,address to,uint256 id,uint256 nonce)");

    bytes32 public constant QUORUM_HASH=
        keccak256("SetQuorum(uint256 newQuorum,uint256 nonce)");
    
    bytes32 public constant TRUSTED_ADDRESS_HASH=
        keccak256("setTrustedAddress(address addr,bool tursted,uint256 nonce)");


    uint256 public quorum;
    mapping(address=>bool) public trusted;

    receive() external payable {}

/// @dev 无需做防重入，nonce天然抗重入
/// @param _name 钱包名字
/// @param signers 初始签名者地址
    constructor(
        string memory _name,
        address[] memory signers,
        uint256 _quorum
    ) payable {
        name=_name;
        quorum = _quorum;

/// @dev 初始化为1能够轻微减少首次使用钱包合约时的gas
        nonce=1;
        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = calculateDomainSeparator();

/// @dev 永远不会溢出
        unchecked {
            for (uint256 i=0;i<signers.length;++i) {
                trusted[signers[i]]=true;
            }
        }
    }

    function verify(bytes32 digest, Signature[] calldata signatures) internal view {
        /// @dev 使用digest和签名共同恢复地址
        /// @dev 当恢复出的签名彼此之间无序或重复(这两项检查也是要求地址升序的原因)，或不在trusted的信任列表里，触发InvaildSignatures错误
        address previous;
        unchecked {
            for (uint256 i=0; i<quorum; ++i ) {
                address signer = ecrecover(digest,signatures[i].v, signatures[i].r, signatures[i].s);

                if (!trusted[signer] || previous >= signer)
                    revert InvaildSignatures();
                
                previous = signer;
            }
        }
    }

/// @dev 执行取款Ether
/// @param signatures 签名数组。该签名数组参数中的签名对应的地址必须是升序的
    function executeEther(Signature[] calldata signatures, address target,uint256 amount, bytes calldata data) external {
    
    /// @dev 由domainSeparator、EXECUTE_ETHER_HASH、nonce共同计算的digest，digest用来参与恢复地址
    /// @dev domainSeparator的计算过程由于有钱包合约的地址及chainid的参与且在chainid变动时会自动重新计算,因此在所有的区块链网络上是唯一的
    /// @dev EXECUTE_ETHER_HASH指明了用户想要调用的函数是executeEther，接下来的四个参数正是传递给executeEther函数的参数
        bytes32 digest = keccak256(
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
    
        verify(digest,signatures);

    /// @dev 当data为空且目标地址是合约地址时，receive函数被调用，如果没有receive函数则fallback被调用
    /// @dev 当data不为空且目标地址是合约地址时，将调用fallback函数或使用data解析出的目标函数和参数
        (bool successful,) = target.call{value:amount}(data);
        if (!successful) revert ExecutionFailed();

        emit Executed(target,amount,data);
    }

    function executeERC20(Signature[] calldata signatures,address token,address target,uint256 amount) external {
        bytes32 digest = keccak256(
				abi.encodePacked(
					'\x19\x01',
					domainSeparator(),
					keccak256(
						abi.encode(
                            EXECUTE_ERC20_HASH,
                            token,
                            target,
							amount,
							nonce++
						)
					)
				)
			);
        
        verify(digest,signatures);

    /// @dev RC20代币的转账操作. 模仿uniswapv2的_safeTransferFrom实现，能够应对非标准的ERC20实现
        (bool success, bytes memory data) = address(token).call(
            abi.encodeWithSignature(
                "transfer(address,uint256)",
                target,
                amount
            )
        );

        if (!success || (data.length != 0 && !abi.decode(data, (bool))))
            revert ExecutionFailed();
        
    }

    function executeNFT(Signature[] calldata signatures,address nftToken,address from,address to,uint256 id) external {
        bytes32 digest = keccak256(
				abi.encodePacked(
					'\x19\x01',
					domainSeparator(),
					keccak256(
						abi.encode(
							EXECUTE_ERC721_HASH,
                            nftToken,
                            from,
							to,
							id,
							nonce++
						)
					)
				)
			);
        
        verify(digest,signatures);

        ERC721(nftToken).safeTransferFrom(from,to,id);
    }

/// @dev 注意此处并未做任何有效性校验，因此直接和setQuorum交互有风险，用户应该通过路由合约与钱包进行交互
    function setQuorum(Signature[] calldata signatures, uint256 newQuorum) external {
        bytes32 digest = keccak256(
				abi.encodePacked(
					'\x19\x01',
					domainSeparator(),
					keccak256(
						abi.encode(
							QUORUM_HASH,
                            newQuorum,
							nonce++
						)
					)
				)
			);
        
        verify(digest,signatures);

        quorum = newQuorum;
        emit QuorumUpdated(quorum);
    }

/// @dev 设置某个地址为信任或不信任的签名者。同样地，有效性校验及相关状态的维护在路由合约中实现
    function setTrustedAddress(Signature[] calldata signatures,address addr,bool trusted_or_not) external {
        if (addr==address(0))
            revert ExecutionFailed();

        bytes32 digest = keccak256(
				abi.encodePacked(
					'\x19\x01',
					domainSeparator(),
					keccak256(
						abi.encode(
							TRUSTED_ADDRESS_HASH,
                            addr,
                            trusted_or_not,
							nonce++
						)
					)
				)
			);
        
        verify(digest,signatures);

        trusted[addr]=trusted_or_not;
        emit TrustedAddressUpdated(addr,trusted_or_not);
    }

/// @dev 模仿solmate库的ERC20中permit的实现，能够应对硬分叉或fork等会造成block.chainid改变的情况
/// @dev 当chainid改变时，domainSeparator会重新计算，使得之前的签名无效
    function domainSeparator()  public view returns (bytes32) {
        return INITIAL_CHAIN_ID == block.chainid ? INITIAL_DOMAIN_SEPARATOR : calculateDomainSeparator();
    }

    function calculateDomainSeparator() view internal returns(bytes32) {
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

    /// ERC721TokenReceiver interface log  ///
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external virtual returns (bytes4) {
        return 0x150b7a02;
    }

    struct Signature {
        uint8 v;
        bytes32 r;
        bytes32 s;
    }
}