// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.14;

import "solmate/tokens/ERC721.sol";
import "openzeppelin-contracts/contracts/utils/Strings.sol";

contract MockNFT is ERC721 {
    
    /// ERROR ///
    error IncorrectMintPrice();
    error MaxSupplyReached();
    error QueryForNonexistentToken();

    using Strings for uint256;
    string public baseURI;
    uint256 public currentTokenId;
    uint256 public constant TOTAL_SUPPLY=10_1000;
    uint256 public constant MINT_PRICE=0.08 ether;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _baseURI
    ) ERC721 (_name,_symbol){
        baseURI=_baseURI;
    }

    function mintTo(address recipient) public payable returns(uint256 newTokenId) {
        if (msg.value!=MINT_PRICE)
            revert IncorrectMintPrice();
        
        if((newTokenId=++currentTokenId)>TOTAL_SUPPLY)
            revert MaxSupplyReached();
        
        _safeMint(recipient,newTokenId);
    }

/// @notice 传入tokenId,返回json格式的元数据，其中有存放NFT的链接(可以是IPFS link,也可以是web2 link)，该NFT的描述信息等元信息
/// @notice 如OpenSea的平台会根据这些信息在前端将NFT的相关内容展示出来
/// @notice 但加密猫的NFT的图片就存在于它们自己的服务器上，如果某天它们关闭服务器用户只会得到一串无意义的16进制数字

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory)
    {
        require(
            ownerOf(tokenId) != address(0),
            "ERC721Metadata: URI query for nonexistent token"
        );

        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, tokenId.toString()))
                : "";
    }
}