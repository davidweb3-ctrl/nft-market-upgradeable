// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./NFTMarketUpgradeable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

/**
 * @title NFTMarketUpgradeableV2
 * @dev 可升级的 NFT 市场合约 V2 版本
 * @notice 在 V1 基础上添加离线签名上架功能
 */
contract NFTMarketUpgradeableV2 is NFTMarketUpgradeable {
    using ECDSA for bytes32;
    using MessageHashUtils for bytes32;

    /// @dev 签名上架事件
    event NFTListedWithSignature(
        bytes32 indexed listingId,
        address indexed seller,
        address indexed nftContract,
        uint256 tokenId,
        uint256 price,
        uint256 timestamp,
        bytes signature
    );

    /// @dev 错误：无效签名
    error InvalidSignature();
    
    /// @dev 错误：签名已使用
    error SignatureAlreadyUsed(bytes32 signatureHash);

    /// @dev 已使用的签名哈希映射
    mapping(bytes32 => bool) public usedSignatures;

    /// @dev 签名上架的数据结构
    struct SignatureListingData {
        address nftContract;  // NFT 合约地址
        uint256 tokenId;      // Token ID
        uint256 price;        // 价格
        uint256 nonce;        // 随机数，防止重放攻击
        uint256 deadline;     // 签名过期时间
    }

    /**
     * @dev 使用签名上架 NFT
     * @param nftContract NFT 合约地址
     * @param tokenId Token ID
     * @param price 价格（wei）
     * @param nonce 随机数
     * @param deadline 签名过期时间
     * @param signature 签名
     */
    function listWithSignature(
        address nftContract,
        uint256 tokenId,
        uint256 price,
        uint256 nonce,
        uint256 deadline,
        bytes calldata signature
    ) external whenNotPaused nonReentrant {
        require(price >= minPrice && price <= maxPrice, "Price out of range");
        require(block.timestamp <= deadline, "Signature expired");
        
        // 验证签名
        address signer = _verifySignature(nftContract, tokenId, price, nonce, deadline, signature);
        
        // 检查签名者是否为 NFT 拥有者
        IERC721 nft = IERC721(nftContract);
        require(nft.ownerOf(tokenId) == signer, "Signer not NFT owner");
        
        // 检查是否已授权市场合约
        require(nft.isApprovedForAll(signer, address(this)) || 
                nft.getApproved(tokenId) == address(this), "Market not approved");

        // 生成上架 ID
        bytes32 listingId = keccak256(abi.encodePacked(
            signer,
            nftContract,
            tokenId,
            price,
            block.timestamp,
            nonce
        ));

        // 检查上架是否已存在
        require(!listings[listingId].active, "Listing already exists");

        // 创建上架信息
        listings[listingId] = Listing({
            seller: signer,
            nftContract: nftContract,
            tokenId: tokenId,
            price: price,
            active: true,
            timestamp: block.timestamp
        });

        // 添加到用户上架列表
        userListings[signer].push(listingId);
        activeListingsCount++;

        // 转移 NFT 到市场合约
        nft.safeTransferFrom(signer, address(this), tokenId);

        emit NFTListed(listingId, signer, nftContract, tokenId, price, block.timestamp);
        emit NFTListedWithSignature(listingId, signer, nftContract, tokenId, price, block.timestamp, signature);
    }

    /**
     * @dev 验证签名
     * @param nftContract NFT 合约地址
     * @param tokenId Token ID
     * @param price 价格
     * @param nonce 随机数
     * @param deadline 过期时间
     * @param signature 签名
     * @return 签名者地址
     */
    function _verifySignature(
        address nftContract,
        uint256 tokenId,
        uint256 price,
        uint256 nonce,
        uint256 deadline,
        bytes calldata signature
    ) internal returns (address) {
        // 构建签名数据
        bytes32 messageHash = keccak256(abi.encodePacked(
            nftContract,
            tokenId,
            price,
            nonce,
            deadline,
            address(this) // 包含合约地址防止跨链重放
        ));
        
        // 添加以太坊签名前缀
        bytes32 ethSignedMessageHash = messageHash.toEthSignedMessageHash();
        
        // 恢复签名者地址
        address signer = ethSignedMessageHash.recover(signature);
        
        // 检查签名是否已使用
        bytes32 signatureHash = keccak256(signature);
        if (usedSignatures[signatureHash]) {
            revert SignatureAlreadyUsed(signatureHash);
        }
        
        // 标记签名为已使用
        usedSignatures[signatureHash] = true;
        
        require(signer != address(0), "Invalid signature");
        return signer;
    }

    /**
     * @dev 获取签名数据哈希（用于前端签名）
     * @param nftContract NFT 合约地址
     * @param tokenId Token ID
     * @param price 价格
     * @param nonce 随机数
     * @param deadline 过期时间
     * @return 签名数据哈希
     */
    function getSignatureHash(
        address nftContract,
        uint256 tokenId,
        uint256 price,
        uint256 nonce,
        uint256 deadline
    ) external view returns (bytes32) {
        bytes32 messageHash = keccak256(abi.encodePacked(
            nftContract,
            tokenId,
            price,
            nonce,
            deadline,
            address(this)
        ));
        return messageHash; // 返回原始哈希，不添加以太坊前缀
    }

    /**
     * @dev 检查签名是否已使用
     * @param signature 签名
     * @return 是否已使用
     */
    function isSignatureUsed(bytes calldata signature) external view returns (bool) {
        bytes32 signatureHash = keccak256(signature);
        return usedSignatures[signatureHash];
    }

    /**
     * @dev 获取合约版本
     * @return 版本号
     */
    function version() public pure override returns (string memory) {
        return "2.0.0";
    }

    /**
     * @dev 重写 _authorizeUpgrade 函数，仅限拥有者可以升级
     * @param newImplementation 新的实现合约地址
     */
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {
        // 可以在这里添加额外的升级授权逻辑
    }
}
