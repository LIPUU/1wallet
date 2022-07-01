# 1wallet

一个用于**教学目的**的**多签钱包**项目，具有以下特性：

* 采用了一流的web3框架[Foundry](https://github.com/foundry-rs/foundry)，使用TDD模式开发，编写了详尽的单元测试 / 模糊测试和适当的注释
* 涵盖了 链上签名验证、 [ERC20](https://eips.ethereum.org/EIPS/eip-20), [ERC721](https://eips.ethereum.org/EIPS/eip-721), [ERC165](https://eips.ethereum.org/EIPS/eip-165), [ERC712](https://eips.ethereum.org/EIPS/eip-712), [ERC2162](https://eips.ethereum.org/EIPS/eip-2612) 等常用技术

### 使用说明

1. [安装Foundry](https://book.getfoundry.sh/getting-started/installation.html)
2. `forge install Rari-Capital/solmate openzeppelin/openzeppelin-contracts` 安装solmate和openzeppelin合约开发库
3. `forge test` 在本地进行测试
4. 参照[Foundry book](https://book.getfoundry.sh/tutorials/solidity-scripting.html), `forge script script/Deploy.s.sol:MyScript --rpc-url $RINKEBY_RPC_URL  --private-key $PRIVATE_KEY --broadcast --verify --etherscan-api-key $ETHERSCAN_KEY -vvvv` 在Rinnkeby测试网部署Router合约并验证代码
5. 与Router合约的`createWallet`方法交互以创建钱包，后续除设置新的多签人数和设置信任地址需要与Router合约交互，取款相关的操作均直接与钱包合约交互。

```ml
.
├── script
│   └── Deploy.s.sol --向以太坊网络部署合约的Solidity script, Foundry only
├── src
│   ├── 1walletRouter.sol --用户在创建钱包,设置信任地址,修改多签人数时直接交互的合约
│   ├── 1wallet.sol --钱包主合约
│   └── Mock
│       ├── MockERC20.sol --测试时使用的MockERC20合约
│       └── MockERC721.sol --测试时用的MockERC721合约
└── test
    ├── 1walletRouter.t.sol --Router的测试合约
    ├── execution_erc20.t.sol --ERC20 token 提款功能的测试合约
    ├── execution_erc721.t.sol --ERC721 token取出功能的测试合约
    ├── execution_ether.t.sol --Ether 提款功能的测试合约
    ├── setQuorum.t.sol --设置新多签人数的测试合约
    ├── setTrustedAddress.t.sol --设置信任地址功能的测试合约
    └── unit.sol --模拟用户链下签名的工具合约，供给上述合约使用
```

---

## **关键概念理解(新手向)**

### **1. 签名, 验证, EIP712**
#### **签名**:
以太坊通过对原始消息进行签名，可以得到签名后的消息，矿工在执行交易前需要对签名进行验证以确定真伪。

某个原始交易可能是这样的：
```json
{
  "id": 2,
  "jsonrpc": "2.0",
  "method": "account_signTransaction",
  "params": [
    {
      "from": "0x1923f626bb8dc025849e00f99c25fe2b2f7fb0db",
      "gas": "0x55555",
      "maxFeePerGas": "0x1234",
      "maxPriorityFeePerGas": "0x1234",
      "input": "0xa0712d6800000000000000000000000000000000000000000000000000000000000000fa",
      "nonce": "0x0",
      "to": "0x07a565b7ed7d7a678680a4c162885bedbb695fe0",
      "value": "0x1234"
    }
  ]
}
```
input不为空，这是个EOA→合约帐户的交易。在单纯转账的情况下input是空的，因为“from”、“to”和“value”字段已经确定了这笔交易的发起方、接收方、金额大小。  
明确几个概念，数字签名算法DSA（ Digital Signature Algorithm ）, 椭圆曲线算法ECC，而ECDSA是ECC与DSA的结合，被称为椭圆曲线数字签名算法。整个签名过程与DSA类似，所不一样的是签名中采取的算法为ECC。所以被称为ECDSA。
<div style="text-align: center">
<img src="./imgs/secp256k1.png"/>
</div>  
以太坊使用的secp256k1是指ECDSA(椭圆曲线数字签名算法)曲线的参数。ECDSA 执行签名操作之后得到的签名由两个数字（整数）组成：r 和 s。以太坊还引入了额外的参数v(恢复标识符),则最终签名可以表示成 {r, s, v}。

在创建签名时，要先准备好一条待签署的原始消息(交易)，和用来签署该消息的私钥(d)。

**这意味着只有EOA有能力进行签名，因为合约帐户没有私钥。**

简化的签名步骤即使用 私钥+ECDSA算法对原始消息的哈希进行密码学运算最终得到r，s，v。在solidity层面，这三个签名数据的类型是uint256,uint256,uint8.  
也就是说{r, s, v} 签名可以组成一个长达 65 字节的序列：r 有 32 个字节，s 有 32 个字节，v 有一个字节。

>在以太坊上，通常使用 `Keccak256("\x19Ethereum Signed Message:\n32" + Keccak256(message))`来计算哈希值。这样，在计算过程中由于引入了明确的和以太坊相关的字符，正常情况下可以确保该签名不能在以太坊之外使用。  
>其实原始的表达形式是 `Keccak256("\x19Ethereum Signed Message:\n" +length(message) + message)` ,但往往实际用在签名过程中的message都是被Hash过的，长度为固定的32字节，因此就变成了：`Keccak256("\x19Ethereum Signed Message:\n32" + Keccak256(message))` 

如果我们将该签名编码成一个十六进制的字符串，我们最后会得到一个 130 个字符长的字符串( 65bytes=130个hex字符)。大多数钱包和界面都会使用这个字符串。一个完整的签名示例如下图所示：
```json
{
	"address": "0x76e01859d6cf4a8637350bdb81e3cef71e29b7c2",
	"msg": "原始交易消息",
	"sig": "0x21fbf0696d5e0aa2ef41a2b4ffb623bcaf070461d61cf7251c74161f82fec3a4370854bc0a34b3ab487c1bc021cd318c734c51ae29374f2beb0e6f2dd49b4bf41c",
	"version": "2"
}
```
#### **验证**:
正如上述示例所示，用户发起一笔交易，需要给矿工提供：
1. 原始消息(交易)
2. 签署该消息的私钥对应的地址
3. {r, s, v} 签名本身

验证过程其实就是从**签名+原始消息中恢复出一个地址**，该地址如果等于消息中附带的地址，则验证通过。否则验证失败。
#### **EIP712**:
EIP712全称`Ethereum typed structured data hashing and signing`,它描述了如何一般性地构建一个函数的签名，该标准使得前端能够对签名有更好的显示，不再只是含混地显示一个16进制的签名(非专业用户很难从头构建得到签名并和前端进行比对以确认他们执行的签名确实是自己期望所期望执行的)，而是更加清晰地向用户展示了它们所签的内容。同时该项技术能够使链下签名更有用，在该多签钱包项目中有体现。  
**EIP712有几个需要深刻理解的核心点：**
1. `DOMAIN_SEPARATOR`  
    `DOMAIN_SEPARATOR`就是一个哈希值，用来独一无二地标识一个合约。为了完成该目的，它的计算过程一定引入了相关的信息。
    ```solidity
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
    ```
2. PERMIT_TYPEHASH
3. nonces variable


### **2. ERC2612**

### **3. 多签钱包工作原理**

### **4. ERC165与ERC721**


