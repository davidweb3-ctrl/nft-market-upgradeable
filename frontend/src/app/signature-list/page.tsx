'use client';

import { useState } from 'react';
import { useAccount, useReadContract, useWriteContract, useWaitForTransactionReceipt, useSignMessage } from 'wagmi';
import { parseEther, hashMessage } from 'viem';
import { CONTRACT_ADDRESSES, NFT_ABI, MARKET_ABI } from '@/lib/contracts';
import Navbar from '@/components/navbar';

export default function SignatureListPage() {
  const { address } = useAccount();
  const [tokenId, setTokenId] = useState('');
  const [price, setPrice] = useState('');
  const [nonce, setNonce] = useState('');
  const [deadline, setDeadline] = useState('');
  const [signature, setSignature] = useState('');
  const [signatureHash, setSignatureHash] = useState('');

  // 检查用户是否已授权市场合约
  const { data: isApproved } = useReadContract({
    address: CONTRACT_ADDRESSES.NFT,
    abi: NFT_ABI,
    functionName: 'isApprovedForAll',
    args: address ? [address, CONTRACT_ADDRESSES.MARKET] : undefined,
  });

  const { data: hash, writeContract, isPending } = useWriteContract();
  const { isLoading: isConfirming, isSuccess: isConfirmed } = useWaitForTransactionReceipt({
    hash,
  });

  const { signMessageAsync, isPending: isSigning } = useSignMessage();

  // 生成智能nonce（基于时间戳 + 随机数）
  const generateNonce = () => {
    const timestamp = Math.floor(Date.now() / 1000);
    const randomPart = Math.floor(Math.random() * 10000);
    // 使用更合理的nonce生成方式：时间戳后6位 + 随机数
    const smartNonce = (timestamp % 1000000) * 10000 + randomPart;
    setNonce(smartNonce.toString());
  };

  // 生成当前时间戳作为deadline（24小时后）
  const generateDeadline = () => {
    const currentTime = Math.floor(Date.now() / 1000);
    const deadline = currentTime + (24 * 60 * 60); // 24小时后
    setDeadline(deadline.toString());
  };

  // 动态确定当前步骤
  const getCurrentStep = () => {
    if (!address) return 0;
    if (!isApproved) return 1; // 需要授权
    if (!signature) return 2; // 需要签名
    return 3; // 可以上架
  };

  const currentStep = getCurrentStep();

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

  // 使用 useReadContract 来获取签名哈希
  const { data: contractSignatureHash, refetch: refetchSignatureHash } = useReadContract({
    address: CONTRACT_ADDRESSES.MARKET,
    abi: MARKET_ABI,
    functionName: 'getSignatureHash',
    args: tokenId && price && nonce && deadline ? [
      CONTRACT_ADDRESSES.NFT,
      BigInt(tokenId),
      parseEther(price),
      BigInt(nonce),
      BigInt(deadline)
    ] : undefined,
  });

  const handleGetSignatureHash = async () => {
    if (!tokenId || !price || !nonce || !deadline) {
      alert('Please fill in all fields first');
      return;
    }

    try {
      // 触发合约调用
      const result = await refetchSignatureHash();
      if (result.data) {
        setSignatureHash(result.data);
      }
    } catch (error) {
      console.error('Error getting signature hash:', error);
    }
  };

  const handleSign = async () => {
    if (!signatureHash) {
      alert('Please get signature hash first');
      return;
    }

    try {
      // 对原始哈希进行签名
      const sig = await signMessageAsync({
        message: { raw: signatureHash as `0x${string}` },
      });
      setSignature(sig);
    } catch (error) {
      console.error('Error signing message:', error);
    }
  };

  const handleListWithSignature = async () => {
    if (!tokenId || !price || !nonce || !deadline || !signature) {
      alert('Please complete all steps first');
      return;
    }

    try {
      writeContract({
        address: CONTRACT_ADDRESSES.MARKET,
        abi: MARKET_ABI,
        functionName: 'listWithSignature',
        args: [
          CONTRACT_ADDRESSES.NFT,
          BigInt(tokenId),
          parseEther(price),
          BigInt(nonce),
          BigInt(deadline),
          signature as `0x${string}`,
        ],
      });
    } catch (error) {
      console.error('Error listing with signature:', error);
    }
  };

  return (
    <div className="min-h-screen bg-gray-50">
      <Navbar />
      <main className="max-w-4xl mx-auto py-6 sm:px-6 lg:px-8">
        <div className="px-4 py-6 sm:px-0">
          <h1 className="text-3xl font-bold text-gray-900 mb-8">Signature List NFT (V2)</h1>
          <p className="text-gray-600 mb-8">
            Use offline signature to list your NFT without on-chain transactions for each listing.
          </p>

          {/* Step 1: Approve Marketplace */}
          <div className="bg-white rounded-lg shadow p-6 mb-6">
            <div className="flex items-center mb-4">
              <div className={`w-8 h-8 rounded-full flex items-center justify-center text-white font-bold ${
                currentStep > 1 ? 'bg-green-500' : currentStep === 1 ? 'bg-blue-500' : 'bg-gray-300'
              }`}>
                1
              </div>
              <h2 className="text-xl font-semibold text-gray-900 ml-3">Approve Marketplace</h2>
            </div>
            <p className="text-gray-600 mb-4">
              Allow the marketplace contract to manage your NFTs (one-time setup).
            </p>
            <button
              onClick={handleApprove}
              disabled={isPending || isConfirming || currentStep > 1}
              className="bg-blue-600 text-white px-4 py-2 rounded-md hover:bg-blue-700 disabled:opacity-50 disabled:cursor-not-allowed"
            >
              {isPending ? 'Approving...' : isConfirming ? 'Confirming...' : 'Approve Marketplace'}
            </button>
            {isConfirmed && currentStep === 1 && (
              <div className="mt-2 text-green-600 text-sm">
                ✅ Marketplace approved successfully!
              </div>
            )}
          </div>

          {/* Step 2: Create Signature */}
          <div className="bg-white rounded-lg shadow p-6 mb-6">
            <div className="flex items-center mb-4">
              <div className={`w-8 h-8 rounded-full flex items-center justify-center text-white font-bold ${
                currentStep > 2 ? 'bg-green-500' : currentStep === 2 ? 'bg-blue-500' : 'bg-gray-300'
              }`}>
                2
              </div>
              <h2 className="text-xl font-semibold text-gray-900 ml-3">Create Signature</h2>
            </div>
            <p className="text-gray-600 mb-4">
              Create an offline signature for your NFT listing.
            </p>
            
            <div className="space-y-4">
              <div className="grid grid-cols-2 gap-4">
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
              </div>
              
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-2">
                    Nonce
                  </label>
                  <div className="flex gap-2">
                    <input
                      type="number"
                      value={nonce}
                      onChange={(e) => setNonce(e.target.value)}
                      placeholder="Enter nonce"
                      className="flex-1 px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 text-gray-900 bg-white placeholder-gray-500"
                    />
                    <button
                      type="button"
                      onClick={generateNonce}
                      className="px-3 py-2 bg-green-600 text-white rounded-md hover:bg-green-700 focus:outline-none focus:ring-2 focus:ring-green-500 text-sm"
                    >
                      Generate
                    </button>
                  </div>
                  <p className="mt-1 text-xs text-gray-500">
                    💡 Nonce用于防止重放攻击，每次使用不同的值
                  </p>
                </div>
                
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-2">
                    Deadline (Unix timestamp)
                  </label>
                  <div className="flex gap-2">
                    <input
                      type="number"
                      value={deadline}
                      onChange={(e) => setDeadline(e.target.value)}
                      placeholder="Enter deadline"
                      className="flex-1 px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 text-gray-900 bg-white placeholder-gray-500"
                    />
                    <button
                      type="button"
                      onClick={generateDeadline}
                      className="px-3 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-blue-500 text-sm"
                    >
                      +24h
                    </button>
                  </div>
                  <p className="mt-1 text-xs text-gray-500">
                    💡 设置签名有效期，建议24小时后过期
                  </p>
                </div>
              </div>
              
              <div className="space-y-2">
                <button
                  onClick={handleGetSignatureHash}
                  disabled={!tokenId || !price || !nonce || !deadline}
                  className="bg-purple-600 text-white px-4 py-2 rounded-md hover:bg-purple-700 disabled:opacity-50 disabled:cursor-not-allowed"
                >
                  Get Signature Hash
                </button>
                
                {signatureHash && (
                  <div className="p-2 bg-white border rounded text-gray-900">
                    <p className="text-sm font-medium text-gray-700">Signature Hash:</p>
                    <p className="text-xs text-green-900 break-all">{signatureHash}</p>
                  </div>
                )}
                
                <button
                  onClick={handleSign}
                  disabled={!signatureHash || isSigning}
                  className="bg-indigo-600 text-white px-4 py-2 rounded-md hover:bg-indigo-700 disabled:opacity-50 disabled:cursor-not-allowed"
                >
                  {isSigning ? 'Signing...' : 'Sign Message'}
                </button>
                
                {signature && (
                  <div className="p-2 bg-white border rounded text-gray-900">
                    <p className="text-sm font-medium text-gray-700">Signature:</p>
                    <p className="text-xs text-green-900 break-all">{signature}</p>
                  </div>
                )}
              </div>
            </div>
          </div>

          {/* Step 3: Submit Signature */}
          <div className="bg-white rounded-lg shadow p-6">
            <div className="flex items-center mb-4">
              <div className={`w-8 h-8 rounded-full flex items-center justify-center text-white font-bold ${
                currentStep === 3 ? 'bg-blue-500' : 'bg-gray-300'
              }`}>
                3
              </div>
              <h2 className="text-xl font-semibold text-gray-900 ml-3">Submit Signature</h2>
            </div>
            <p className="text-gray-600 mb-4">
              Submit your signed message to list the NFT.
            </p>
            
            <button
              onClick={handleListWithSignature}
              disabled={isPending || isConfirming || currentStep !== 3}
              className="w-full bg-green-600 text-white px-4 py-2 rounded-md hover:bg-green-700 disabled:opacity-50 disabled:cursor-not-allowed"
            >
              {isPending ? 'Sending Transaction...' : isConfirming ? 'Confirming...' : 'List NFT with Signature'}
            </button>
            
            {isConfirmed && currentStep === 3 && (
              <div className="mt-2 text-green-600 text-sm">
                ✅ NFT listed with signature successfully!
              </div>
            )}
          </div>
        </div>
      </main>
    </div>
  );
}