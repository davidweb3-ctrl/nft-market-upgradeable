import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  // 禁用 SSR 以避免 indexedDB 问题
  experimental: {
    esmExternals: false,
  },
  // 配置 webpack 以处理客户端依赖
  webpack: (config, { isServer }) => {
    if (isServer) {
      // 在服务端忽略客户端特定的模块
      config.externals = config.externals || [];
      config.externals.push({
        'idb-keyval': 'commonjs idb-keyval',
        '@walletconnect/keyvaluestorage': 'commonjs @walletconnect/keyvaluestorage',
        '@walletconnect/core': 'commonjs @walletconnect/core',
        '@walletconnect/sign-client': 'commonjs @walletconnect/sign-client',
        '@walletconnect/universal-provider': 'commonjs @walletconnect/universal-provider',
        '@walletconnect/ethereum-provider': 'commonjs @walletconnect/ethereum-provider',
      });
    }
    return config;
  },
};

export default nextConfig;
