'use client';

import { useReadContract } from 'wagmi';
import { CONTRACT_ADDRESSES, MARKET_ABI } from '@/lib/contracts';
import Navbar from '@/components/navbar';
import NFTCard from '@/components/nft-card';

export default function HomePage() {
  const { data: activeListingsCount } = useReadContract({
    address: CONTRACT_ADDRESSES.MARKET,
    abi: MARKET_ABI,
    functionName: 'activeListingsCount',
  });

  const { data: feePercentage } = useReadContract({
    address: CONTRACT_ADDRESSES.MARKET,
    abi: MARKET_ABI,
    functionName: 'feePercentage',
  });

  const { data: version } = useReadContract({
    address: CONTRACT_ADDRESSES.MARKET,
    abi: MARKET_ABI,
    functionName: 'version',
  });

  return (
    <div className="min-h-screen bg-gray-50">
      <Navbar />
      <main className="max-w-7xl mx-auto py-6 sm:px-6 lg:px-8">
        <div className="px-4 py-6 sm:px-0">
          <div className="text-center mb-8">
            <h1 className="text-3xl font-bold text-gray-900 mb-4">
              NFT Marketplace V2
            </h1>
            <p className="text-lg text-gray-600 mb-6">
              Upgradeable NFT Marketplace with Offline Signature Listing
            </p>
            
            {/* 市场统计 */}
            <div className="grid grid-cols-1 md:grid-cols-3 gap-6 mb-8">
              <div className="bg-white p-6 rounded-lg shadow">
                <h3 className="text-lg font-medium text-gray-900">Active Listings</h3>
                <p className="text-3xl font-bold text-blue-600">
                  {activeListingsCount?.toString() || '0'}
                </p>
              </div>
              <div className="bg-white p-6 rounded-lg shadow">
                <h3 className="text-lg font-medium text-gray-900">Platform Fee</h3>
                <p className="text-3xl font-bold text-green-600">
                  {feePercentage ? (Number(feePercentage) / 100).toFixed(1) : '0.0'}%
                </p>
              </div>
              <div className="bg-white p-6 rounded-lg shadow">
                <h3 className="text-lg font-medium text-gray-900">Version</h3>
                <p className="text-3xl font-bold text-purple-600">
                  {version || 'V1'}
                </p>
              </div>
            </div>
          </div>

          {/* NFT 列表区域 */}
          <div className="bg-white rounded-lg shadow p-6">
            <h2 className="text-xl font-semibold text-gray-900 mb-4">
              Available NFTs
            </h2>
            <div className="text-center py-8 text-gray-500">
              <p>No NFTs available for purchase at the moment.</p>
              <p className="text-sm mt-2">
                List your NFTs to get started!
              </p>
            </div>
          </div>
        </div>
      </main>
    </div>
  );
}
