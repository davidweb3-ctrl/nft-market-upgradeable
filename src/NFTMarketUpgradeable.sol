// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

/**
 * @title NFTMarketUpgradeable
 * @dev 可升级的 NFT 市场合约
 * @notice 支持 NFT 上架、购买、下架等功能，使用原生 ETH 作为支付方式
 */
contract NFTMarketUpgradeable is 
    Initializable,
    OwnableUpgradeable, 
    UUPSUpgradeable,
    ReentrancyGuardUpgradeable,
    PausableUpgradeable,
    IERC721Receiver
{
    /// @dev 市场手续费（以基点计算，100 = 1%）
    uint256 public feePercentage;
    
    /// @dev 市场手续费接收地址
    address public feeRecipient;
    
    /// @dev 最小价格（防止垃圾上架）
    uint256 public minPrice;
    
    /// @dev 最大价格（防止溢出）
    uint256 public maxPrice;

    /// @dev 上架信息结构体
    struct Listing {
        address seller;           // 卖家地址
        address nftContract;      // NFT 合约地址
        uint256 tokenId;          // Token ID
        uint256 price;            // 价格（wei）
        bool active;              // 是否活跃
        uint256 timestamp;        // 上架时间
    }

    /// @dev 所有上架信息
    mapping(bytes32 => Listing) public listings;
    
    /// @dev 用户的所有上架 ID
    mapping(address => bytes32[]) public userListings;
    
    /// @dev 活跃上架数量
    uint256 public activeListingsCount;

    /// @dev 事件：NFT 上架
    event NFTListed(
        bytes32 indexed listingId,
        address indexed seller,
        address indexed nftContract,
        uint256 tokenId,
        uint256 price,
        uint256 timestamp
    );

    /// @dev 事件：NFT 购买
    event NFTPurchased(
        bytes32 indexed listingId,
        address indexed buyer,
        address indexed seller,
        address nftContract,
        uint256 tokenId,
        uint256 price,
        uint256 fee,
        uint256 timestamp
    );

    /// @dev 事件：NFT 下架
    event NFTDelisted(
        bytes32 indexed listingId,
        address indexed seller,
        address indexed nftContract,
        uint256 tokenId,
        uint256 timestamp
    );

    /// @dev 事件：市场参数更新
    event MarketParamsUpdated(
        uint256 feePercentage,
        address feeRecipient,
        uint256 minPrice,
        uint256 maxPrice
    );

    /// @dev 错误：上架不存在
    error ListingNotFound(bytes32 listingId);
    
    /// @dev 错误：上架不活跃
    error ListingNotActive(bytes32 listingId);
    
    /// @dev 错误：价格超出范围
    error PriceOutOfRange(uint256 price, uint256 minPrice, uint256 maxPrice);
    
    /// @dev 错误：不是 NFT 拥有者
    error NotNFTOwner(address nftContract, uint256 tokenId);
    
    /// @dev 错误：不是上架者
    error NotLister(bytes32 listingId);
    
    /// @dev 错误：支付金额不足
    error InsufficientPayment(uint256 required, uint256 provided);
    
    /// @dev 错误：NFT 转移失败
    error NFTTransferFailed();

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        // _disableInitializers(); // 在测试环境中注释掉
    }

    /**
     * @dev 初始化函数
     * @param _feePercentage 手续费百分比（基点）
     * @param _feeRecipient 手续费接收地址
     * @param _minPrice 最小价格
     * @param _maxPrice 最大价格
     */
    function initialize(
        uint256 _feePercentage,
        address _feeRecipient,
        uint256 _minPrice,
        uint256 _maxPrice
    ) public initializer {
        __Ownable_init(msg.sender);
        __UUPSUpgradeable_init();
        __ReentrancyGuard_init();
        __Pausable_init();

        require(_feePercentage <= 1000, "Fee percentage too high"); // 最大 10%
        require(_feeRecipient != address(0), "Invalid fee recipient");
        require(_minPrice > 0, "Min price must be greater than 0");
        require(_maxPrice > _minPrice, "Max price must be greater than min price");

        feePercentage = _feePercentage;
        feeRecipient = _feeRecipient;
        minPrice = _minPrice;
        maxPrice = _maxPrice;
    }

    /**
     * @dev 上架 NFT
     * @param nftContract NFT 合约地址
     * @param tokenId Token ID
     * @param price 价格（wei）
     */
    function listNFT(
        address nftContract,
        uint256 tokenId,
        uint256 price
    ) external whenNotPaused nonReentrant {
        require(price >= minPrice && price <= maxPrice, "Price out of range");
        
        // 检查调用者是否为 NFT 拥有者
        IERC721 nft = IERC721(nftContract);
        require(nft.ownerOf(tokenId) == msg.sender, "Not NFT owner");
        
        // 检查是否已授权市场合约
        require(nft.isApprovedForAll(msg.sender, address(this)) || 
                nft.getApproved(tokenId) == address(this), "Market not approved");

        // 生成上架 ID
        bytes32 listingId = keccak256(abi.encodePacked(
            msg.sender,
            nftContract,
            tokenId,
            price,
            block.timestamp
        ));

        // 检查上架是否已存在
        require(!listings[listingId].active, "Listing already exists");

        // 创建上架信息
        listings[listingId] = Listing({
            seller: msg.sender,
            nftContract: nftContract,
            tokenId: tokenId,
            price: price,
            active: true,
            timestamp: block.timestamp
        });

        // 添加到用户上架列表
        userListings[msg.sender].push(listingId);
        activeListingsCount++;

        // 转移 NFT 到市场合约
        nft.safeTransferFrom(msg.sender, address(this), tokenId);

        emit NFTListed(listingId, msg.sender, nftContract, tokenId, price, block.timestamp);
    }

    /**
     * @dev 购买 NFT
     * @param listingId 上架 ID
     */
    function buyNFT(bytes32 listingId) external payable whenNotPaused nonReentrant {
        Listing storage listing = listings[listingId];
        
        if (!listing.active) {
            revert ListingNotActive(listingId);
        }

        // 检查支付金额
        if (msg.value < listing.price) {
            revert InsufficientPayment(listing.price, msg.value);
        }

        // 计算手续费
        uint256 fee = (listing.price * feePercentage) / 10000;
        uint256 sellerAmount = listing.price - fee;

        // 标记上架为非活跃
        listing.active = false;
        activeListingsCount--;

        // 转移 NFT 给买家
        IERC721 nft = IERC721(listing.nftContract);
        nft.safeTransferFrom(address(this), msg.sender, listing.tokenId);

        // 转移资金
        if (fee > 0) {
            (bool feeSuccess, ) = feeRecipient.call{value: fee}("");
            require(feeSuccess, "Fee transfer failed");
        }

        (bool sellerSuccess, ) = listing.seller.call{value: sellerAmount}("");
        require(sellerSuccess, "Seller payment failed");

        // 退还多余的 ETH
        if (msg.value > listing.price) {
            (bool refundSuccess, ) = msg.sender.call{value: msg.value - listing.price}("");
            require(refundSuccess, "Refund failed");
        }

        emit NFTPurchased(
            listingId,
            msg.sender,
            listing.seller,
            listing.nftContract,
            listing.tokenId,
            listing.price,
            fee,
            block.timestamp
        );
    }

    /**
     * @dev 下架 NFT
     * @param listingId 上架 ID
     */
    function delistNFT(bytes32 listingId) external whenNotPaused nonReentrant {
        Listing storage listing = listings[listingId];
        
        if (!listing.active) {
            revert ListingNotActive(listingId);
        }

        if (listing.seller != msg.sender) {
            revert NotLister(listingId);
        }

        // 标记上架为非活跃
        listing.active = false;
        activeListingsCount--;

        // 转移 NFT 回给卖家
        IERC721 nft = IERC721(listing.nftContract);
        nft.safeTransferFrom(address(this), msg.sender, listing.tokenId);

        emit NFTDelisted(listingId, msg.sender, listing.nftContract, listing.tokenId, block.timestamp);
    }

    /**
     * @dev 获取用户的所有上架
     * @param user 用户地址
     * @return 上架 ID 数组
     */
    function getUserListings(address user) external view returns (bytes32[] memory) {
        return userListings[user];
    }

    /**
     * @dev 获取上架详情
     * @param listingId 上架 ID
     * @return 上架信息
     */
    function getListing(bytes32 listingId) external view returns (Listing memory) {
        return listings[listingId];
    }

    /**
     * @dev 更新市场参数（仅拥有者）
     * @param _feePercentage 新的手续费百分比
     * @param _feeRecipient 新的手续费接收地址
     * @param _minPrice 新的最小价格
     * @param _maxPrice 新的最大价格
     */
    function updateMarketParams(
        uint256 _feePercentage,
        address _feeRecipient,
        uint256 _minPrice,
        uint256 _maxPrice
    ) external onlyOwner {
        require(_feePercentage <= 1000, "Fee percentage too high");
        require(_feeRecipient != address(0), "Invalid fee recipient");
        require(_minPrice > 0, "Min price must be greater than 0");
        require(_maxPrice > _minPrice, "Max price must be greater than min price");

        feePercentage = _feePercentage;
        feeRecipient = _feeRecipient;
        minPrice = _minPrice;
        maxPrice = _maxPrice;

        emit MarketParamsUpdated(_feePercentage, _feeRecipient, _minPrice, _maxPrice);
    }

    /**
     * @dev 暂停市场（仅拥有者）
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @dev 恢复市场（仅拥有者）
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @dev 紧急提取 ETH（仅拥有者）
     * @param amount 提取金额
     */
    function emergencyWithdraw(uint256 amount) external onlyOwner {
        require(address(this).balance >= amount, "Insufficient balance");
        (bool success, ) = owner().call{value: amount}("");
        require(success, "Withdrawal failed");
    }

    /**
     * @dev 重写 _authorizeUpgrade 函数，仅限拥有者可以升级
     * @param newImplementation 新的实现合约地址
     */
    function _authorizeUpgrade(address newImplementation) internal virtual override onlyOwner {
        // 可以在这里添加额外的升级授权逻辑
    }

    /**
     * @dev 实现 IERC721Receiver 接口
     * @param operator 操作者地址
     * @param from 发送者地址
     * @param tokenId Token ID
     * @param data 额外数据
     * @return 选择器
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external pure override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    /**
     * @dev 获取合约版本
     * @return 版本号
     */
    function version() public pure virtual returns (string memory) {
        return "1.0.0";
    }

    /**
     * @dev 检查是否支持接口
     * @param interfaceId 接口 ID
     * @return 是否支持该接口
     */
    function supportsInterface(bytes4 interfaceId) public pure returns (bool) {
        return interfaceId == 0x01ffc9a7; // ERC165
    }

    /**
     * @dev 获取市场统计信息
     * @return _activeListingsCount 活跃上架数量
     * @return _contractBalance 合约余额
     * @return _feePercentage 手续费百分比
     */
    function getMarketStats() external view returns (
        uint256 _activeListingsCount,
        uint256 _contractBalance,
        uint256 _feePercentage
    ) {
        return (activeListingsCount, address(this).balance, feePercentage);
    }
}
