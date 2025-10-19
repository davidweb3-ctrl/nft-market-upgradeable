// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {MyNFTUpgradeable} from "../src/MyNFTUpgradeable.sol";
import {NFTMarketUpgradeable} from "../src/NFTMarketUpgradeable.sol";
import {NFTMarketUpgradeableV2} from "../src/NFTMarketUpgradeableV2.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

/**
 * @title NFTMarketUpgradeableV2Test
 * @dev NFTMarketUpgradeableV2 合约的测试用例
 */
contract NFTMarketUpgradeableV2Test is Test {
    NFTMarketUpgradeable public marketV1;
    NFTMarketUpgradeableV2 public marketV2;
    MyNFTUpgradeable public nft;
    
    // 测试参数
    uint256 constant FEE_PERCENTAGE = 250; // 2.5%
    uint256 constant MIN_PRICE = 0.001 ether;
    uint256 constant MAX_PRICE = 100 ether;
    uint256 constant NFT_PRICE = 1 ether;
    
    // 测试地址
    address public owner;
    address public seller;
    address public buyer;
    address public feeRecipient;
    
    // 签名相关
    uint256 private sellerPrivateKey;
    uint256 private nonOwnerPrivateKey;
    
    event NFTListedWithSignature(
        bytes32 indexed listingId,
        address indexed seller,
        address indexed nftContract,
        uint256 tokenId,
        uint256 price,
        uint256 timestamp,
        bytes signature
    );

    function setUp() public {
        // 设置测试地址
        owner = makeAddr("owner");
        seller = makeAddr("seller");
        buyer = makeAddr("buyer");
        feeRecipient = makeAddr("feeRecipient");
        
        // 设置私钥
        sellerPrivateKey = 0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d;
        nonOwnerPrivateKey = 0x47e179ec197488593b187f80a5eb0fce6d0c8e4d7177c0e51a2310d0409b804f;
        
        // 部署 NFT 合约
        nft = new MyNFTUpgradeable();
        vm.prank(owner);
        nft.initialize("Test NFT", "TNFT", "https://test.com/", 10000);
        
        // 部署 V1 市场合约
        marketV1 = new NFTMarketUpgradeable();
        vm.prank(owner);
        marketV1.initialize(FEE_PERCENTAGE, feeRecipient, MIN_PRICE, MAX_PRICE);
        
        // 铸造 NFT 给卖家
        vm.prank(owner);
        nft.mint(seller);
        
        // 卖家授权市场合约
        vm.prank(seller);
        nft.setApprovalForAll(address(marketV1), true);
        
        // 给买家一些 ETH
        vm.deal(buyer, 10 ether);
    }

    // ============ 升级测试 ============

    function test_UpgradeToV2() public {
        // 先在 V1 上上架一个 NFT
        vm.prank(seller);
        marketV1.listNFT(address(nft), 1, NFT_PRICE);
        
        // 验证 V1 状态
        assertEq(marketV1.activeListingsCount(), 1, "V1 should have 1 active listing");
        
        // 部署 V2 合约
        marketV2 = new NFTMarketUpgradeableV2();
        
        // 升级到 V2
        vm.prank(owner);
        marketV1.upgradeToAndCall(address(marketV2), "");
        
        // 验证升级后的合约
        assertEq(marketV1.version(), "2.0.0", "Version should be 2.0.0");
        assertEq(marketV1.activeListingsCount(), 1, "V2 should preserve V1 listings");
        
        // 验证原有功能仍然工作
        bytes32[] memory userListings = marketV1.getUserListings(seller);
        assertEq(userListings.length, 1, "User listings should be preserved");
        
        // 验证可以购买 V1 上架的 NFT
        bytes32 listingId = userListings[0];
        vm.prank(buyer);
        marketV1.buyNFT{value: NFT_PRICE}(listingId);
        
        assertEq(nft.ownerOf(1), buyer, "NFT should be transferred to buyer");
        assertEq(marketV1.activeListingsCount(), 0, "Active listings should be 0 after purchase");
    }

    // ============ 签名上架测试 ============

    function test_ListWithSignature() public {
        // 升级到 V2
        marketV2 = new NFTMarketUpgradeableV2();
        vm.prank(owner);
        marketV1.upgradeToAndCall(address(marketV2), "");
        
        uint256 tokenId = 1;
        uint256 price = NFT_PRICE;
        uint256 nonce = 12345;
        uint256 deadline = block.timestamp + 1 hours;
        
        // 创建签名
        bytes memory signature = _createSignature(
            address(nft),
            tokenId,
            price,
            nonce,
            deadline,
            sellerPrivateKey
        );
        
        // 使用签名上架
        vm.prank(buyer); // 任何人都可以调用，但签名必须是 NFT 拥有者
        NFTMarketUpgradeableV2(address(marketV1)).listWithSignature(
            address(nft),
            tokenId,
            price,
            nonce,
            deadline,
            signature
        );
        
        // 验证上架成功
        assertEq(marketV1.activeListingsCount(), 1, "Should have 1 active listing");
        assertEq(nft.ownerOf(tokenId), address(marketV1), "NFT should be transferred to market");
        
        // 验证用户上架列表
        bytes32[] memory userListings = marketV1.getUserListings(seller);
        assertEq(userListings.length, 1, "Seller should have 1 listing");
    }

    function test_ListWithSignature_InvalidSignature() public {
        // 升级到 V2
        marketV2 = new NFTMarketUpgradeableV2();
        vm.prank(owner);
        marketV1.upgradeToAndCall(address(marketV2), "");
        
        uint256 tokenId = 1;
        uint256 price = NFT_PRICE;
        uint256 nonce = 12345;
        uint256 deadline = block.timestamp + 1 hours;
        
        // 使用非拥有者的私钥创建签名
        bytes memory signature = _createSignature(
            address(nft),
            tokenId,
            price,
            nonce,
            deadline,
            nonOwnerPrivateKey
        );
        
        // 尝试使用无效签名上架
        vm.prank(buyer);
        vm.expectRevert("Signer not NFT owner");
        NFTMarketUpgradeableV2(address(marketV1)).listWithSignature(
            address(nft),
            tokenId,
            price,
            nonce,
            deadline,
            signature
        );
    }

    function test_ListWithSignature_SignatureExpired() public {
        // 升级到 V2
        marketV2 = new NFTMarketUpgradeableV2();
        vm.prank(owner);
        marketV1.upgradeToAndCall(address(marketV2), "");
        
        uint256 tokenId = 1;
        uint256 price = NFT_PRICE;
        uint256 nonce = 12345;
        uint256 deadline = block.timestamp - 1; // 已过期
        
        // 创建签名
        bytes memory signature = _createSignature(
            address(nft),
            tokenId,
            price,
            nonce,
            deadline,
            sellerPrivateKey
        );
        
        // 尝试使用过期签名上架
        vm.prank(buyer);
        vm.expectRevert("Signature expired");
        NFTMarketUpgradeableV2(address(marketV1)).listWithSignature(
            address(nft),
            tokenId,
            price,
            nonce,
            deadline,
            signature
        );
    }

    function test_ListWithSignature_SignatureReuse() public {
        // 升级到 V2
        marketV2 = new NFTMarketUpgradeableV2();
        vm.prank(owner);
        marketV1.upgradeToAndCall(address(marketV2), "");
        
        uint256 tokenId = 1;
        uint256 price = NFT_PRICE;
        uint256 nonce = 12345;
        uint256 deadline = block.timestamp + 1 hours;
        
        // 创建签名
        bytes memory signature = _createSignature(
            address(nft),
            tokenId,
            price,
            nonce,
            deadline,
            sellerPrivateKey
        );
        
        // 第一次使用签名上架
        vm.prank(buyer);
        NFTMarketUpgradeableV2(address(marketV1)).listWithSignature(
            address(nft),
            tokenId,
            price,
            nonce,
            deadline,
            signature
        );
        
        // 铸造新的 NFT
        vm.prank(owner);
        nft.mint(seller);
        
        // 尝试重复使用签名
        vm.prank(buyer);
        vm.expectRevert();
        NFTMarketUpgradeableV2(address(marketV1)).listWithSignature(
            address(nft),
            2, // 不同的 tokenId
            price,
            nonce,
            deadline,
            signature
        );
    }

    function test_ListWithSignature_PriceOutOfRange() public {
        // 升级到 V2
        marketV2 = new NFTMarketUpgradeableV2();
        vm.prank(owner);
        marketV1.upgradeToAndCall(address(marketV2), "");
        
        uint256 tokenId = 1;
        uint256 price = MIN_PRICE - 1; // 价格过低
        uint256 nonce = 12345;
        uint256 deadline = block.timestamp + 1 hours;
        
        // 创建签名
        bytes memory signature = _createSignature(
            address(nft),
            tokenId,
            price,
            nonce,
            deadline,
            sellerPrivateKey
        );
        
        // 尝试使用无效价格上架
        vm.prank(buyer);
        vm.expectRevert("Price out of range");
        NFTMarketUpgradeableV2(address(marketV1)).listWithSignature(
            address(nft),
            tokenId,
            price,
            nonce,
            deadline,
            signature
        );
    }

    // ============ 签名验证测试 ============

    function test_GetSignatureHash() public {
        // 升级到 V2
        marketV2 = new NFTMarketUpgradeableV2();
        vm.prank(owner);
        marketV1.upgradeToAndCall(address(marketV2), "");
        
        uint256 tokenId = 1;
        uint256 price = NFT_PRICE;
        uint256 nonce = 12345;
        uint256 deadline = block.timestamp + 1 hours;
        
        // 获取签名哈希
        bytes32 signatureHash = NFTMarketUpgradeableV2(address(marketV1)).getSignatureHash(
            address(nft),
            tokenId,
            price,
            nonce,
            deadline
        );
        
        // 验证签名哈希不为零
        assertTrue(signatureHash != bytes32(0), "Signature hash should not be zero");
    }

    function test_IsSignatureUsed() public {
        // 升级到 V2
        marketV2 = new NFTMarketUpgradeableV2();
        vm.prank(owner);
        marketV1.upgradeToAndCall(address(marketV2), "");
        
        uint256 tokenId = 1;
        uint256 price = NFT_PRICE;
        uint256 nonce = 12345;
        uint256 deadline = block.timestamp + 1 hours;
        
        // 创建签名
        bytes memory signature = _createSignature(
            address(nft),
            tokenId,
            price,
            nonce,
            deadline,
            sellerPrivateKey
        );
        
        // 验证签名未使用
        assertFalse(NFTMarketUpgradeableV2(address(marketV1)).isSignatureUsed(signature), "Signature should not be used initially");
        
        // 使用签名上架
        vm.prank(buyer);
        NFTMarketUpgradeableV2(address(marketV1)).listWithSignature(
            address(nft),
            tokenId,
            price,
            nonce,
            deadline,
            signature
        );
        
        // 验证签名已使用
        assertTrue(NFTMarketUpgradeableV2(address(marketV1)).isSignatureUsed(signature), "Signature should be used after listing");
    }

    // ============ 集成测试 ============

    function test_FullV2Workflow() public {
        // 升级到 V2
        marketV2 = new NFTMarketUpgradeableV2();
        vm.prank(owner);
        marketV1.upgradeToAndCall(address(marketV2), "");
        
        uint256 tokenId = 1;
        uint256 price = NFT_PRICE;
        uint256 nonce = 12345;
        uint256 deadline = block.timestamp + 1 hours;
        
        // 创建签名
        bytes memory signature = _createSignature(
            address(nft),
            tokenId,
            price,
            nonce,
            deadline,
            sellerPrivateKey
        );
        
        // 1. 使用签名上架 NFT
        vm.prank(buyer);
        NFTMarketUpgradeableV2(address(marketV1)).listWithSignature(
            address(nft),
            tokenId,
            price,
            nonce,
            deadline,
            signature
        );
        
        // 2. 验证上架
        assertEq(marketV1.activeListingsCount(), 1, "Should have 1 active listing");
        assertEq(nft.ownerOf(tokenId), address(marketV1), "NFT should be in market");
        
        // 3. 购买 NFT
        bytes32[] memory userListings = marketV1.getUserListings(seller);
        bytes32 listingId = userListings[0];
        
        vm.prank(buyer);
        marketV1.buyNFT{value: price}(listingId);
        
        // 4. 验证购买结果
        assertEq(nft.ownerOf(tokenId), buyer, "Buyer should own NFT");
        assertEq(marketV1.activeListingsCount(), 0, "Should have 0 active listings");
    }

    // ============ 辅助函数 ============

    /**
     * @dev 创建签名
     */
    function _createSignature(
        address nftContract,
        uint256 tokenId,
        uint256 price,
        uint256 nonce,
        uint256 deadline,
        uint256 privateKey
    ) internal view returns (bytes memory) {
        bytes32 messageHash = keccak256(abi.encodePacked(
            nftContract,
            tokenId,
            price,
            nonce,
            deadline,
            address(marketV1)
        ));
        
        bytes32 ethSignedMessageHash = keccak256(abi.encodePacked(
            "\x19Ethereum Signed Message:\n32",
            messageHash
        ));
        
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey, ethSignedMessageHash);
        return abi.encodePacked(r, s, v);
    }
}
