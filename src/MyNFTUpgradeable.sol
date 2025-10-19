// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

/**
 * @title MyNFTUpgradeable
 * @dev 可升级的 ERC721 NFT 合约
 * @notice 使用 UUPS 升级模式，仅合约拥有者可以铸造 NFT
 */
contract MyNFTUpgradeable is 
    Initializable,
    ERC721Upgradeable, 
    OwnableUpgradeable, 
    UUPSUpgradeable 
{
    /// @dev 用于跟踪下一个可用的 token ID
    uint256 private _nextTokenId;

    /// @dev 基础 URI，用于构建 tokenURI
    string private _baseTokenURI;

    /// @dev 最大供应量
    uint256 public maxSupply;

    /// @dev 事件：NFT 铸造
    event NFTMinted(address indexed to, uint256 indexed tokenId);

    /// @dev 事件：基础 URI 更新
    event BaseURIUpdated(string newBaseURI);

    /// @dev 事件：最大供应量更新
    event MaxSupplyUpdated(uint256 newMaxSupply);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        // _disableInitializers(); // 在测试环境中注释掉
    }

    /**
     * @dev 初始化函数，替代构造函数
     * @param name NFT 集合名称
     * @param symbol NFT 集合符号
     * @param baseTokenURI 基础 URI
     * @param _maxSupply 最大供应量
     */
    function initialize(
        string memory name,
        string memory symbol,
        string memory baseTokenURI,
        uint256 _maxSupply
    ) public initializer {
        __ERC721_init(name, symbol);
        __Ownable_init(msg.sender);
        __UUPSUpgradeable_init();

        _baseTokenURI = baseTokenURI;
        maxSupply = _maxSupply;
        
        // 从 token ID 1 开始
        _nextTokenId = 1;
    }

    /**
     * @dev 铸造 NFT，仅限合约拥有者
     * @param to 接收者地址
     * @return tokenId 铸造的 token ID
     */
    function mint(address to) public onlyOwner returns (uint256) {
        require(to != address(0), "MyNFT: mint to zero address");
        require(_nextTokenId <= maxSupply, "MyNFT: max supply exceeded");

        uint256 tokenId = _nextTokenId;
        _nextTokenId++;
        
        _safeMint(to, tokenId);
        
        emit NFTMinted(to, tokenId);
        return tokenId;
    }

    /**
     * @dev 批量铸造 NFT
     * @param to 接收者地址
     * @param amount 铸造数量
     */
    function mintBatch(address to, uint256 amount) public onlyOwner {
        require(to != address(0), "MyNFT: mint to zero address");
        require(amount > 0, "MyNFT: amount must be greater than 0");
        require(_nextTokenId + amount - 1 <= maxSupply, "MyNFT: max supply exceeded");

        for (uint256 i = 0; i < amount; i++) {
            uint256 tokenId = _nextTokenId;
            _nextTokenId++;
            _safeMint(to, tokenId);
            emit NFTMinted(to, tokenId);
        }
    }

    /**
     * @dev 获取当前 token ID 计数器值
     * @return 下一个可用的 token ID
     */
    function getCurrentTokenId() public view returns (uint256) {
        return _nextTokenId;
    }

    /**
     * @dev 获取已铸造的 NFT 数量
     * @return 已铸造的 NFT 数量
     */
    function totalSupply() public view returns (uint256) {
        return _nextTokenId - 1;
    }

    /**
     * @dev 设置基础 URI
     * @param newBaseURI 新的基础 URI
     */
    function setBaseURI(string memory newBaseURI) public onlyOwner {
        _baseTokenURI = newBaseURI;
        emit BaseURIUpdated(newBaseURI);
    }

    /**
     * @dev 设置最大供应量
     * @param newMaxSupply 新的最大供应量
     */
    function setMaxSupply(uint256 newMaxSupply) public onlyOwner {
        require(newMaxSupply >= totalSupply(), "MyNFT: new max supply too low");
        maxSupply = newMaxSupply;
        emit MaxSupplyUpdated(newMaxSupply);
    }

    /**
     * @dev 重写 _baseURI 函数
     * @return 基础 URI
     */
    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    /**
     * @dev 重写 _authorizeUpgrade 函数，仅限拥有者可以升级
     * @param newImplementation 新的实现合约地址
     */
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {
        // 可以在这里添加额外的升级授权逻辑
    }

    /**
     * @dev 获取合约版本信息
     * @return 版本号
     */
    function version() public pure returns (string memory) {
        return "1.0.0";
    }

    /**
     * @dev 检查是否支持接口
     * @param interfaceId 接口 ID
     * @return 是否支持该接口
     */
    function supportsInterface(bytes4 interfaceId) 
        public 
        view 
        override(ERC721Upgradeable) 
        returns (bool) 
    {
        return super.supportsInterface(interfaceId);
    }
}
