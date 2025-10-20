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

export const config = getDefaultConfig({
  appName: process.env.NEXT_PUBLIC_APP_NAME || 'NFT Market V2',
  projectId: process.env.NEXT_PUBLIC_WALLETCONNECT_PROJECT_ID || 'your-project-id',
  chains: [localhost, mainnet, sepolia, polygon, optimism, arbitrum, base],
  ssr: true,
});
