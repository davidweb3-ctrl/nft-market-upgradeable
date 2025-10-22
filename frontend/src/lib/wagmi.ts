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

export const config = getDefaultConfig({
  appName: process.env.NEXT_PUBLIC_APP_NAME || 'NFT Market V2',
  projectId: process.env.NEXT_PUBLIC_WALLETCONNECT_PROJECT_ID || 'your-project-id',
  chains: [localhost, mainnet, sepolia, polygon, optimism, arbitrum, base],
  ssr: false, // 禁用服务端渲染以避免依赖问题
  // 只在浏览器环境中启用 WalletConnect
  ...(isBrowser && {
    connectors: {
      walletConnect: {
        projectId: process.env.NEXT_PUBLIC_WALLETCONNECT_PROJECT_ID || 'your-project-id',
      },
    },
  }),
});
