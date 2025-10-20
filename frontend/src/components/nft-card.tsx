'use client';

import { useReadContract, useWriteContract, useWaitForTransactionReceipt } from 'wagmi';
import { parseEther, formatEther } from 'viem';
import { CONTRACT_ADDRESSES, MARKET_ABI } from '@/lib/contracts';
import Image from 'next/image';

interface NFTCardProps {
  listingId: string;
  seller: string;
  nftContract: string;
  tokenId: bigint;
  price: bigint;
  active: boolean;
  timestamp: bigint;
}

export default function NFTCard({
  listingId,
  seller,
  nftContract,
  tokenId,
  price,
  active,
  timestamp,
}: NFTCardProps) {
  const { data: hash, writeContract, isPending } = useWriteContract();
  const { isLoading: isConfirming, isSuccess: isConfirmed } = useWaitForTransactionReceipt({
    hash,
  });

  const handleBuy = async () => {
    try {
      writeContract({
        address: CONTRACT_ADDRESSES.MARKET,
        abi: MARKET_ABI,
        functionName: 'buyNFT',
        args: [listingId as `0x${string}`],
        value: price,
      });
    } catch (error) {
      console.error('Error buying NFT:', error);
    }
  };

  const handleDelist = async () => {
    try {
      writeContract({
        address: CONTRACT_ADDRESSES.MARKET,
        abi: MARKET_ABI,
        functionName: 'delistNFT',
        args: [listingId as `0x${string}`],
      });
    } catch (error) {
      console.error('Error delisting NFT:', error);
    }
  };

  if (!active) {
    return null;
  }

  return (
    <div className="bg-white rounded-lg shadow-md overflow-hidden">
      <div className="p-4">
        <div className="text-center">
          <div className="text-2xl font-bold text-blue-600 mb-2">
            #{tokenId.toString()}
          </div>
          <div className="text-lg font-semibold text-gray-900 mb-2">
            {formatEther(price)} ETH
          </div>
          <div className="text-sm text-gray-500 mb-4">
            Seller: {seller.slice(0, 6)}...{seller.slice(-4)}
          </div>
          <div className="space-y-2">
            <button
              onClick={handleBuy}
              disabled={isPending || isConfirming}
              className="w-full bg-blue-600 text-white py-2 px-4 rounded-md hover:bg-blue-700 disabled:opacity-50 disabled:cursor-not-allowed"
            >
              {isPending ? 'Sending...' : isConfirming ? 'Confirming...' : 'Buy NFT'}
            </button>
            <button
              onClick={handleDelist}
              disabled={isPending || isConfirming}
              className="w-full bg-gray-600 text-white py-2 px-4 rounded-md hover:bg-gray-700 disabled:opacity-50 disabled:cursor-not-allowed"
            >
              {isPending ? 'Sending...' : isConfirming ? 'Confirming...' : 'Delist'}
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}
