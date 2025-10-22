'use client';

import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { WagmiProvider } from 'wagmi';
import { RainbowKitProvider } from '@rainbow-me/rainbowkit';
import '@rainbow-me/rainbowkit/styles.css';
import { useEffect, useState } from 'react';
import dynamic from 'next/dynamic';

const queryClient = new QueryClient();

// 动态导入配置以避免 SSR 问题
const WagmiConfig = dynamic(() => import('@/lib/wagmi-client'), {
  ssr: false,
  loading: () => <div>Loading...</div>,
});

export function Providers({ children }: { children: React.ReactNode }) {
  const [mounted, setMounted] = useState(false);
  const [config, setConfig] = useState<any>(null);

  useEffect(() => {
    setMounted(true);
    // 动态导入配置
    import('@/lib/wagmi-client').then((module) => {
      setConfig(module.config);
    });
  }, []);

  if (!mounted || !config) {
    return <div>Loading...</div>;
  }

  return (
    <WagmiProvider config={config}>
      <QueryClientProvider client={queryClient}>
        <RainbowKitProvider>
          {children}
        </RainbowKitProvider>
      </QueryClientProvider>
    </WagmiProvider>
  );
}
