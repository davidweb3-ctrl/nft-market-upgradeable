# NFT Market V2 前端使用指南

## 概述

这是一个基于 Next.js 15 + Viem + Wagmi + RainbowKit 的 NFT 市场前端应用，支持可升级的 NFT 市场合约的 V1 和 V2 功能。

## 功能特性

### V1 功能
- **NFT 铸造**: 用户可以铸造新的 NFT
- **市场授权**: 授权市场合约管理用户的 NFT
- **标准上架**: 直接在链上上架 NFT
- **NFT 购买**: 购买其他用户上架的 NFT
- **下架功能**: 下架自己上架的 NFT

### V2 功能
- **离线签名上架**: 使用签名方式上架 NFT，减少链上交易
- **签名验证**: 验证用户签名的有效性
- **批量操作**: 支持批量签名和上架

## 页面说明

### 1. 首页 (`/`)
- 显示市场统计信息
- 显示活跃上架数量
- 显示平台费用比例
- 显示合约版本信息

### 2. 上架页面 (`/list`)
- **我的 NFT**: 显示用户拥有的所有 NFT（包括已上架的）
- **步骤 1**: 铸造 NFT
- **步骤 2**: 授权市场合约
- **步骤 3**: 上架 NFT

### 3. 签名上架页面 (`/signature-list`)
- **步骤 1**: 授权市场合约（一次性设置）
- **步骤 2**: 创建离线签名
- **步骤 3**: 提交签名上架

## 使用流程

### 标准上架流程

1. **连接钱包**
   - 点击右上角的 "Connect Wallet" 按钮
   - 选择支持的钱包（MetaMask、WalletConnect 等）

2. **铸造 NFT**
   - 进入 "List NFT" 页面
   - 点击 "Mint NFT" 按钮
   - 确认交易

3. **授权市场合约**
   - 在步骤 2 中点击 "Approve Marketplace"
   - 确认授权交易

4. **上架 NFT**
   - 在 "My Owned NFTs" 中选择要上架的 NFT
   - 或手动输入 Token ID
   - 设置价格（ETH）
   - 点击 "List NFT"

### 签名上架流程

1. **一次性授权**
   - 进入 "Signature List" 页面
   - 完成市场合约授权（只需一次）

2. **创建签名**
   - 填写 Token ID、价格、Nonce、截止时间
   - 点击 "Get Signature Hash"
   - 点击 "Sign Message" 签名

3. **提交上架**
   - 点击 "List NFT with Signature"
   - 确认交易

## 技术栈

- **Next.js 15**: React 框架
- **TypeScript**: 类型安全
- **Tailwind CSS**: 样式框架
- **Viem**: 以太坊库
- **Wagmi**: React Hooks for Ethereum
- **RainbowKit**: 钱包连接 UI

## 环境配置

在 `frontend/.env.local` 中配置：

```bash
# 合约地址
NEXT_PUBLIC_NFT_CONTRACT_ADDRESS=0x...
NEXT_PUBLIC_MARKET_CONTRACT_ADDRESS=0x...

# 网络配置
NEXT_PUBLIC_CHAIN_ID=31337
NEXT_PUBLIC_RPC_URL=http://127.0.0.1:8545

# 应用配置
NEXT_PUBLIC_APP_NAME=NFT Market V2
```

## 开发命令

```bash
# 安装依赖
cd frontend
pnpm install

# 启动开发服务器
pnpm dev

# 构建生产版本
pnpm build

# 启动生产服务器
pnpm start
```

## 注意事项

1. **Token ID**: Token ID 从 1 开始，Token ID 0 不存在
2. **价格范围**: 确保价格在合约允许的范围内
3. **授权**: 首次使用需要授权市场合约
4. **签名**: 签名上架需要先完成一次性授权
5. **网络**: 确保连接到正确的网络（本地开发网络）

## 故障排除

### 常见问题

1. **"pending" 状态**
   - 检查 Anvil 是否运行
   - 检查合约地址是否正确
   - 检查网络连接

2. **交易失败**
   - 检查是否有足够的 ETH
   - 检查是否拥有对应的 NFT
   - 检查价格是否在有效范围内

3. **页面刷新后状态丢失**
   - 这是正常现象，状态基于链上数据
   - 重新连接钱包即可恢复

4. **输入值不清晰**
   - 已优化输入框样式，确保高对比度
   - 使用深色文字和白色背景

## 更新日志

- **v1.0.0**: 初始版本，支持 V1 和 V2 功能
- 优化了输入框可见性
- 改进了错误处理
- 添加了用户 NFT 显示功能
- 实现了动态步骤检测