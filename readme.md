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

### 

### 关键概念理解(新手向)

#### 签名与验证


#### 多签钱包

#### ERC165与ERC721

#### ERC721与ERC2612
