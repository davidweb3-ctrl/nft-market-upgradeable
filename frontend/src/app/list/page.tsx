'use client';

import { useState, useEffect } from 'react';
import { useAccount, useReadContract, useWriteContract, useWaitForTransactionReceipt } from 'wagmi';
import { parseEther, formatEther } from 'viem';
import { CONTRACT_ADDRESSES, NFT_ABI, MARKET_ABI } from '@/lib/contracts';
import Navbar from '@/components/navbar';

export default function ListPage() {
  const { address } = useAccount();
  const [tokenId, setTokenId] = useState('');
  const [price, setPrice] = useState('');
  const [ownedNFTs, setOwnedNFTs] = useState<number[]>([]);

  // 检查用户是否已授权市场合约
  const { data: isApproved } = useReadContract({
    address: CONTRACT_ADDRESSES.NFT,
    abi: NFT_ABI,
    functionName: 'isApprovedForAll',
    args: address ? [address, CONTRACT_ADDRESSES.MARKET] : undefined,
  });

  // 检查用户是否拥有 NFT
  const { data: hasNFT } = useReadContract({
    address: CONTRACT_ADDRESSES.NFT,
    abi: NFT_ABI,
    functionName: 'ownerOf',
    args: [1n], // 检查 Token ID 1
  });

  // 检查特定 Token ID 的所有者
  const { data: nftOwner } = useReadContract({
    address: CONTRACT_ADDRESSES.NFT,
    abi: NFT_ABI,
    functionName: 'ownerOf',
    args: tokenId ? [BigInt(tokenId)] : undefined,
  });

  // 获取用户的上架记录
  const { data: userListings } = useReadContract({
    address: CONTRACT_ADDRESSES.MARKET,
    abi: MARKET_ABI,
    functionName: 'getUserListings',
    args: address ? [address] : undefined,
  });

  // 获取上架记录详情
  const { data: listing1 } = useReadContract({
    address: CONTRACT_ADDRESSES.MARKET,
    abi: MARKET_ABI,
    functionName: 'getListing',
    args: userListings && userListings.length > 0 ? [userListings[0]] : undefined,
  });

  const { data: listing2 } = useReadContract({
    address: CONTRACT_ADDRESSES.MARKET,
    abi: MARKET_ABI,
    functionName: 'getListing',
    args: userListings && userListings.length > 1 ? [userListings[1]] : undefined,
  });

  const { data: listing3 } = useReadContract({
    address: CONTRACT_ADDRESSES.MARKET,
    abi: MARKET_ABI,
    functionName: 'getListing',
    args: userListings && userListings.length > 2 ? [userListings[2]] : undefined,
  });

  const { data: listing4 } = useReadContract({
    address: CONTRACT_ADDRESSES.MARKET,
    abi: MARKET_ABI,
    functionName: 'getListing',
    args: userListings && userListings.length > 3 ? [userListings[3]] : undefined,
  });

  // 检查 Token ID 1-5 的所有者
  const { data: ownerOf1 } = useReadContract({
    address: CONTRACT_ADDRESSES.NFT,
    abi: NFT_ABI,
    functionName: 'ownerOf',
    args: [1n],
  });

  const { data: ownerOf2 } = useReadContract({
    address: CONTRACT_ADDRESSES.NFT,
    abi: NFT_ABI,
    functionName: 'ownerOf',
    args: [2n],
  });

  const { data: ownerOf3 } = useReadContract({
    address: CONTRACT_ADDRESSES.NFT,
    abi: NFT_ABI,
    functionName: 'ownerOf',
    args: [3n],
  });

  const { data: ownerOf4 } = useReadContract({
    address: CONTRACT_ADDRESSES.NFT,
    abi: NFT_ABI,
    functionName: 'ownerOf',
    args: [4n],
  });

  const { data: ownerOf5 } = useReadContract({
    address: CONTRACT_ADDRESSES.NFT,
    abi: NFT_ABI,
    functionName: 'ownerOf',
    args: [5n],
  });

  const { data: hash, writeContract, isPending } = useWriteContract();
  const { isLoading: isConfirming, isSuccess: isConfirmed } = useWaitForTransactionReceipt({
    hash,
  });

  // 获取用户拥有的 NFT 列表（包括已上架的）
  useEffect(() => {
    if (!address) return;
    
    const owned: number[] = [];
    
    // 1. 检查用户直接拥有的 Token ID（未上架的）
    if (ownerOf1 && ownerOf1.toLowerCase() === address.toLowerCase()) owned.push(1);
    if (ownerOf2 && ownerOf2.toLowerCase() === address.toLowerCase()) owned.push(2);
    if (ownerOf3 && ownerOf3.toLowerCase() === address.toLowerCase()) owned.push(3);
    if (ownerOf4 && ownerOf4.toLowerCase() === address.toLowerCase()) owned.push(4);
    if (ownerOf5 && ownerOf5.toLowerCase() === address.toLowerCase()) owned.push(5);
    
    // 2. 检查用户上架记录中的 Token ID（已上架的）
    const listings = [listing1, listing2, listing3, listing4].filter(Boolean);
    listings.forEach(listing => {
      if (listing && listing.tokenId && listing.seller.toLowerCase() === address.toLowerCase()) {
        const tokenId = Number(listing.tokenId);
        if (!owned.includes(tokenId)) {
          owned.push(tokenId);
        }
      }
    });
    
    setOwnedNFTs(owned);
  }, [address, ownerOf1, ownerOf2, ownerOf3, ownerOf4, ownerOf5, listing1?.tokenId, listing2?.tokenId, listing3?.tokenId, listing4?.tokenId, listing1?.seller, listing2?.seller, listing3?.seller, listing4?.seller]);

  // 检查特定 Token ID 是否已上架
  const isTokenListed = (tokenId: number) => {
    const listings = [listing1, listing2, listing3, listing4].filter(Boolean);
    return listings.some(listing => 
      listing && 
      Number(listing.tokenId) === tokenId && 
      listing.seller.toLowerCase() === address?.toLowerCase() &&
      listing.active
    );
  };

  // 动态确定当前步骤
  const getCurrentStep = () => {
    if (!address) return 0;
    if (!hasNFT) return 1; // 需要铸造 NFT
    if (!isApproved) return 2; // 需要授权
    return 3; // 可以上架
  };

  const currentStep = getCurrentStep();

  const handleMint = async () => {
    try {
      writeContract({
        address: CONTRACT_ADDRESSES.NFT,
        abi: NFT_ABI,
        functionName: 'mint',
        args: [address!],
      });
    } catch (error) {
      console.error('Error minting NFT:', error);
    }
  };

  const handleApprove = async () => {
    try {
      writeContract({
        address: CONTRACT_ADDRESSES.NFT,
        abi: NFT_ABI,
        functionName: 'setApprovalForAll',
        args: [CONTRACT_ADDRESSES.MARKET, true],
      });
    } catch (error) {
      console.error('Error approving marketplace:', error);
    }
  };

  const handleList = async () => {
    if (tokenId === '0') {
      alert('Token ID 0 does not exist. Please use a valid Token ID (1, 2, 3, etc.)');
      return;
    }

    try {
      writeContract({
        address: CONTRACT_ADDRESSES.MARKET,
        abi: MARKET_ABI,
        functionName: 'listNFT',
        args: [CONTRACT_ADDRESSES.NFT, BigInt(tokenId), parseEther(price)],
      });
    } catch (error: any) {
      console.error('Error listing NFT:', error);
      
      // 提供更具体的错误信息
      if (error.message?.includes('NotNFTOwner')) {
        alert('You are not the owner of this NFT');
      } else if (error.message?.includes('PriceOutOfRange')) {
        alert('Price is out of allowed range');
      } else if (error.message?.includes('execution reverted')) {
        alert('Transaction failed. Please check if you own this NFT and the price is valid.');
      } else if (error.message?.includes('0x7e273289')) {
        alert('Invalid Token ID. Token ID 0 does not exist.');
      } else {
        alert('Failed to list NFT. Please try again.');
      }
    }
  };

  return (
    <div className="min-h-screen bg-gray-50">
      <Navbar />
      <main className="max-w-4xl mx-auto py-6 sm:px-6 lg:px-8">
        <div className="px-4 py-6 sm:px-0">
          <h1 className="text-3xl font-bold text-gray-900 mb-8">List Your NFT</h1>

          {/* My Owned NFTs */}
          <div className="border rounded-lg p-4 mb-8">
            <div className="flex items-center justify-between mb-4">
              <h3 className="text-lg font-medium text-gray-900">
                My Owned NFTs
              </h3>
              <span className="px-2 py-1 text-xs rounded-full bg-blue-100 text-blue-800">
                {ownedNFTs.length} NFT{ownedNFTs.length !== 1 ? 's' : ''}
              </span>
            </div>
            
            {ownedNFTs.length > 0 ? (
              <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-5 gap-3">
                {ownedNFTs.map((tokenId) => {
                  const isListed = isTokenListed(tokenId);
                  return (
                    <div key={tokenId} className="bg-gray-50 rounded-lg p-3 text-center relative">
                      {isListed && (
                        <div className="absolute -top-1 -right-1 bg-green-500 text-white text-xs px-2 py-1 rounded-full">
                          Listed
                        </div>
                      )}
                      <div className="text-2xl font-bold text-blue-600 mb-1">
                        #{tokenId}
                      </div>
                      <div className="text-xs text-gray-500">
                        Token ID {tokenId}
                      </div>
                      {isListed ? (
                        <div className="mt-2 text-xs bg-green-100 text-green-700 px-2 py-1 rounded">
                          Already Listed
                        </div>
                      ) : (
                        <button
                          onClick={() => setTokenId(tokenId.toString())}
                          className="mt-2 text-xs bg-blue-100 text-blue-700 px-2 py-1 rounded hover:bg-blue-200"
                        >
                          Use for Listing
                        </button>
                      )}
                    </div>
                  );
                })}
              </div>
            ) : (
              <div className="text-center py-6 text-gray-500">
                <div className="text-4xl mb-2">🎨</div>
                <p>No NFTs owned yet</p>
                <p className="text-sm">Mint an NFT to get started!</p>
              </div>
            )}
          </div>

          {/* Step 1: Mint NFT */}
          <div className="bg-white rounded-lg shadow p-6 mb-6">
            <div className="flex items-center mb-4">
              <div className={`w-8 h-8 rounded-full flex items-center justify-center text-white font-bold ${
                currentStep > 1 ? 'bg-green-500' : currentStep === 1 ? 'bg-blue-500' : 'bg-gray-300'
              }`}>
                1
              </div>
              <h2 className="text-xl font-semibold text-gray-900 ml-3">Mint NFT</h2>
            </div>
            <p className="text-gray-600 mb-4">
              First, you need to mint an NFT to list on the marketplace.
            </p>
            <button
              onClick={handleMint}
              disabled={isPending || isConfirming || currentStep > 1}
              className="bg-blue-600 text-white px-4 py-2 rounded-md hover:bg-blue-700 disabled:opacity-50 disabled:cursor-not-allowed"
            >
              {isPending ? 'Minting...' : isConfirming ? 'Confirming...' : 'Mint NFT'}
            </button>
            {isConfirmed && currentStep === 1 && (
              <div className="mt-2 text-green-600 text-sm">
                ✅ NFT minted successfully!
              </div>
            )}
          </div>

          {/* Step 2: Approve Marketplace */}
          <div className="bg-white rounded-lg shadow p-6 mb-6">
            <div className="flex items-center mb-4">
              <div className={`w-8 h-8 rounded-full flex items-center justify-center text-white font-bold ${
                currentStep > 2 ? 'bg-green-500' : currentStep === 2 ? 'bg-blue-500' : 'bg-gray-300'
              }`}>
                2
              </div>
              <h2 className="text-xl font-semibold text-gray-900 ml-3">Approve Marketplace</h2>
            </div>
            <p className="text-gray-600 mb-4">
              Allow the marketplace contract to manage your NFTs.
            </p>
            <button
              onClick={handleApprove}
              disabled={isPending || isConfirming || currentStep !== 2}
              className="bg-blue-600 text-white px-4 py-2 rounded-md hover:bg-blue-700 disabled:opacity-50 disabled:cursor-not-allowed"
            >
              {isPending ? 'Approving...' : isConfirming ? 'Confirming...' : 'Approve Marketplace'}
            </button>
            {isConfirmed && currentStep === 2 && (
              <div className="mt-2 text-green-600 text-sm">
                ✅ Marketplace approved successfully!
              </div>
            )}
          </div>

          {/* Step 3: List NFT */}
          <div className="bg-white rounded-lg shadow p-6">
            <div className="flex items-center mb-4">
              <div className={`w-8 h-8 rounded-full flex items-center justify-center text-white font-bold ${
                currentStep === 3 ? 'bg-blue-500' : 'bg-gray-300'
              }`}>
                3
              </div>
              <h2 className="text-xl font-semibold text-gray-900 ml-3">List NFT</h2>
            </div>
            <p className="text-gray-600 mb-4">
              Enter the Token ID and price to list your NFT.
            </p>
            
            <div className="space-y-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  Token ID
                </label>
                <input
                  type="number"
                  value={tokenId}
                  onChange={(e) => setTokenId(e.target.value)}
                  placeholder="Enter Token ID"
                  className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 text-gray-900 bg-white placeholder-gray-500"
                />
                {nftOwner && (
                  <p className="mt-1 text-sm text-gray-600">
                    Owner: {nftOwner.slice(0, 6)}...{nftOwner.slice(-4)}
                    {nftOwner.toLowerCase() === address?.toLowerCase() ? (
                      <span className="text-green-600 ml-2">✓ You own this NFT</span>
                    ) : (
                      <span className="text-red-600 ml-2">✗ You don't own this NFT</span>
                    )}
                  </p>
                )}
                <p className="mt-1 text-xs text-gray-500">
                  💡 Tip: After minting an NFT, use Token ID 1, 2, 3, etc. (Token ID 0 does not exist)
                </p>
              </div>
              
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  Price (ETH)
                </label>
                <input
                  type="number"
                  step="0.01"
                  value={price}
                  onChange={(e) => setPrice(e.target.value)}
                  placeholder="Enter price in ETH"
                  className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 text-gray-900 bg-white placeholder-gray-500"
                />
              </div>
              
              <button
                onClick={handleList}
                disabled={
                  isPending || 
                  isConfirming || 
                  currentStep !== 3 || 
                  !tokenId || 
                  !price || 
                  tokenId === '0' ||
                  nftOwner?.toLowerCase() !== address?.toLowerCase()
                }
                className="w-full bg-green-600 text-white px-4 py-2 rounded-md hover:bg-green-700 disabled:opacity-50 disabled:cursor-not-allowed"
              >
                {isPending ? 'Sending Transaction...' : isConfirming ? 'Confirming...' : 'List NFT'}
              </button>
              
              {isConfirmed && currentStep === 3 && (
                <div className="mt-2 text-green-600 text-sm">
                  ✅ NFT listed successfully!
                </div>
              )}
            </div>
          </div>
        </div>
      </main>
    </div>
  );
}