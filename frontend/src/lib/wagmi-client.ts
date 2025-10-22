import { getDefaultConfig } from '@rainbow-me/rainbowkit';
import { defineChain } from 'viem';
import {
  mainnet,
  sepolia,
  polygon,
  optimism,
  arbitrum,
  base,
} from 'wagmi/chains';

// 定义本地开发链
export const localhost = defineChain({
  id: 31337,
  name: 'Localhost',
  nativeCurrency: {
    decimals: 18,
    name: 'Ether',
    symbol: 'ETH',
  },
  rpcUrls: {
    default: {
      http: ['http://127.0.0.1:8545'],
    },
    public: {
      http: ['http://127.0.0.1:8545'],
    },
  },
  blockExplorers: {
    default: {
      name: 'Local Explorer',
      url: 'http://localhost:8545',
    },
  },
});

// 检查是否在浏览器环境中
const isBrowser = typeof window !== 'undefined';

// 创建一个有效的 WalletConnect projectId（使用示例 ID）
const WALLETCONNECT_PROJECT_ID = '21fef48091f12692cad574a6f7753643';

// 只在客户端创建配置，完全禁用 WalletConnect 在 SSR 中
export const config = getDefaultConfig({
  appName: 'NFT Market V2', // 使用固定值避免环境变量问题
  projectId: WALLETCONNECT_PROJECT_ID, // 始终提供有效的 projectId
  chains: [localhost, mainnet, sepolia, polygon, optimism, arbitrum, base],
  ssr: false,
});
