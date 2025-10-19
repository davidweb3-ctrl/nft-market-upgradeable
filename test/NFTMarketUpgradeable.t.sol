// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {MyNFTUpgradeable} from "../src/MyNFTUpgradeable.sol";
import {NFTMarketUpgradeable} from "../src/NFTMarketUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/**
 * @title NFTMarketUpgradeableTest
 * @dev NFTMarketUpgradeable 合约的测试用例
 */
contract NFTMarketUpgradeableTest is Test {
    NFTMarketUpgradeable public market;
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
    
    event NFTListed(
        bytes32 indexed listingId,
        address indexed seller,
        address indexed nftContract,
        uint256 tokenId,
        uint256 price,
        uint256 timestamp
    );

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

    event NFTDelisted(
        bytes32 indexed listingId,
        address indexed seller,
        address indexed nftContract,
        uint256 tokenId,
        uint256 timestamp
    );

    function setUp() public {
        // 设置测试地址
        owner = makeAddr("owner");
        seller = makeAddr("seller");
        buyer = makeAddr("buyer");
        feeRecipient = makeAddr("feeRecipient");
        
        // 部署 NFT 合约
        nft = new MyNFTUpgradeable();
        vm.prank(owner);
        nft.initialize("Test NFT", "TNFT", "https://test.com/", 10000);
        
        // 部署市场合约
        market = new NFTMarketUpgradeable();
        vm.prank(owner);
        market.initialize(FEE_PERCENTAGE, feeRecipient, MIN_PRICE, MAX_PRICE);
        
        // 铸造 NFT 给卖家
        vm.prank(owner);
        nft.mint(seller);
        
        // 卖家授权市场合约
        vm.prank(seller);
        nft.setApprovalForAll(address(market), true);
        
        // 给买家一些 ETH
        vm.deal(buyer, 10 ether);
    }

    // ============ 部署测试 ============

    function test_Deployment() public view {
        // 验证合约部署成功
        assertTrue(address(market) != address(0), "Market contract not deployed");
        assertTrue(address(nft) != address(0), "NFT contract not deployed");
        
        // 验证市场参数
        assertEq(market.feePercentage(), FEE_PERCENTAGE, "Fee percentage not set correctly");
        assertEq(market.feeRecipient(), feeRecipient, "Fee recipient not set correctly");
        assertEq(market.minPrice(), MIN_PRICE, "Min price not set correctly");
        assertEq(market.maxPrice(), MAX_PRICE, "Max price not set correctly");
        assertEq(market.owner(), owner, "Owner not set correctly");
        assertEq(market.version(), "1.0.0", "Version not set correctly");
    }

    // ============ 上架测试 ============

    function test_ListNFT() public {
        uint256 tokenId = 1;
        
        // 验证 NFT 所有权
        assertEq(nft.ownerOf(tokenId), seller, "Seller should own NFT");
        
        // 上架 NFT
        vm.prank(seller);
        market.listNFT(address(nft), tokenId, NFT_PRICE);
        
        // 验证 NFT 已转移到市场合约
        assertEq(nft.ownerOf(tokenId), address(market), "NFT should be transferred to market");
        
        // 验证上架信息
        bytes32 listingId = keccak256(abi.encodePacked(
            seller,
            address(nft),
            tokenId,
            NFT_PRICE,
            block.timestamp
        ));
        
        // 注意：由于 block.timestamp 在测试中可能不同，我们需要通过事件来验证
        // 这里我们验证活跃上架数量
        assertEq(market.activeListingsCount(), 1, "Active listings count should be 1");
        
        // 验证用户上架列表
        bytes32[] memory userListings = market.getUserListings(seller);
        assertEq(userListings.length, 1, "User should have 1 listing");
    }

    function test_ListNFT_PriceTooLow() public {
        uint256 tokenId = 1;
        uint256 lowPrice = MIN_PRICE - 1;
        
        vm.prank(seller);
        vm.expectRevert("Price out of range");
        market.listNFT(address(nft), tokenId, lowPrice);
    }

    function test_ListNFT_PriceTooHigh() public {
        uint256 tokenId = 1;
        uint256 highPrice = MAX_PRICE + 1;
        
        vm.prank(seller);
        vm.expectRevert("Price out of range");
        market.listNFT(address(nft), tokenId, highPrice);
    }

    function test_ListNFT_NotOwner() public {
        uint256 tokenId = 1;
        
        vm.prank(buyer);
        vm.expectRevert("Not NFT owner");
        market.listNFT(address(nft), tokenId, NFT_PRICE);
    }

    function test_ListNFT_NotApproved() public {
        uint256 tokenId = 1;
        
        // 撤销授权
        vm.prank(seller);
        nft.setApprovalForAll(address(market), false);
        
        vm.prank(seller);
        vm.expectRevert("Market not approved");
        market.listNFT(address(nft), tokenId, NFT_PRICE);
    }

    // ============ 购买测试 ============

    function test_BuyNFT() public {
        uint256 tokenId = 1;
        
        // 先上架 NFT
        vm.prank(seller);
        market.listNFT(address(nft), tokenId, NFT_PRICE);
        
        // 获取用户上架列表来找到上架 ID
        bytes32[] memory userListings = market.getUserListings(seller);
        require(userListings.length > 0, "No listings found");
        bytes32 listingId = userListings[0];
        
        // 记录初始余额
        uint256 initialSellerBalance = seller.balance;
        uint256 initialFeeRecipientBalance = feeRecipient.balance;
        uint256 initialMarketBalance = address(market).balance;
        
        // 购买 NFT
        vm.prank(buyer);
        market.buyNFT{value: NFT_PRICE}(listingId);
        
        // 验证 NFT 所有权转移
        assertEq(nft.ownerOf(tokenId), buyer, "Buyer should own NFT");
        
        // 验证资金转移
        uint256 expectedFee = (NFT_PRICE * FEE_PERCENTAGE) / 10000;
        uint256 expectedSellerAmount = NFT_PRICE - expectedFee;
        
        assertEq(seller.balance, initialSellerBalance + expectedSellerAmount, "Seller should receive correct amount");
        assertEq(feeRecipient.balance, initialFeeRecipientBalance + expectedFee, "Fee recipient should receive fee");
        assertEq(address(market).balance, initialMarketBalance, "Market balance should not change");
        
        // 验证上架状态
        NFTMarketUpgradeable.Listing memory listing = market.getListing(listingId);
        assertFalse(listing.active, "Listing should be inactive after purchase");
        assertEq(market.activeListingsCount(), 0, "Active listings count should be 0");
    }

    function test_BuyNFT_InsufficientPayment() public {
        uint256 tokenId = 1;
        
        // 先上架 NFT
        vm.prank(seller);
        market.listNFT(address(nft), tokenId, NFT_PRICE);
        
        // 获取上架 ID
        bytes32[] memory userListings = market.getUserListings(seller);
        require(userListings.length > 0, "No listings found");
        bytes32 listingId = userListings[0];
        
        // 尝试用不足的金额购买
        vm.prank(buyer);
        vm.expectRevert();
        market.buyNFT{value: NFT_PRICE - 1}(listingId);
    }

    function test_BuyNFT_ExcessPayment() public {
        uint256 tokenId = 1;
        uint256 excessAmount = NFT_PRICE + 0.1 ether;
        
        // 先上架 NFT
        vm.prank(seller);
        market.listNFT(address(nft), tokenId, NFT_PRICE);
        
        // 获取上架 ID
        bytes32[] memory userListings = market.getUserListings(seller);
        require(userListings.length > 0, "No listings found");
        bytes32 listingId = userListings[0];
        
        // 记录初始余额
        uint256 initialBuyerBalance = buyer.balance;
        
        // 用超额金额购买
        vm.prank(buyer);
        market.buyNFT{value: excessAmount}(listingId);
        
        // 验证买家余额（应该退还多余金额）
        uint256 expectedFinalBalance = initialBuyerBalance - NFT_PRICE;
        assertEq(buyer.balance, expectedFinalBalance, "Buyer should be refunded excess amount");
    }

    function test_BuyNFT_ListingNotActive() public {
        bytes32 fakeListingId = keccak256("fake");
        
        vm.prank(buyer);
        vm.expectRevert();
        market.buyNFT{value: NFT_PRICE}(fakeListingId);
    }

    // ============ 下架测试 ============

    function test_DelistNFT() public {
        uint256 tokenId = 1;
        
        // 先上架 NFT
        vm.prank(seller);
        market.listNFT(address(nft), tokenId, NFT_PRICE);
        
        // 获取上架 ID
        bytes32[] memory userListings = market.getUserListings(seller);
        require(userListings.length > 0, "No listings found");
        bytes32 listingId = userListings[0];
        
        // 下架 NFT
        vm.prank(seller);
        market.delistNFT(listingId);
        
        // 验证 NFT 所有权转移回卖家
        assertEq(nft.ownerOf(tokenId), seller, "NFT should be returned to seller");
        
        // 验证上架状态
        NFTMarketUpgradeable.Listing memory listing = market.getListing(listingId);
        assertFalse(listing.active, "Listing should be inactive after delisting");
        assertEq(market.activeListingsCount(), 0, "Active listings count should be 0");
    }

    function test_DelistNFT_NotLister() public {
        uint256 tokenId = 1;
        
        // 先上架 NFT
        vm.prank(seller);
        market.listNFT(address(nft), tokenId, NFT_PRICE);
        
        // 获取上架 ID
        bytes32[] memory userListings = market.getUserListings(seller);
        require(userListings.length > 0, "No listings found");
        bytes32 listingId = userListings[0];
        
        // 非上架者尝试下架
        vm.prank(buyer);
        vm.expectRevert();
        market.delistNFT(listingId);
    }

    // ============ 管理功能测试 ============

    function test_UpdateMarketParams() public {
        uint256 newFeePercentage = 500; // 5%
        address newFeeRecipient = makeAddr("newFeeRecipient");
        uint256 newMinPrice = 0.01 ether;
        uint256 newMaxPrice = 200 ether;
        
        vm.prank(owner);
        market.updateMarketParams(newFeePercentage, newFeeRecipient, newMinPrice, newMaxPrice);
        
        assertEq(market.feePercentage(), newFeePercentage, "Fee percentage should be updated");
        assertEq(market.feeRecipient(), newFeeRecipient, "Fee recipient should be updated");
        assertEq(market.minPrice(), newMinPrice, "Min price should be updated");
        assertEq(market.maxPrice(), newMaxPrice, "Max price should be updated");
    }

    function test_UpdateMarketParams_NonOwner() public {
        vm.prank(seller);
        vm.expectRevert();
        market.updateMarketParams(500, makeAddr("newFeeRecipient"), 0.01 ether, 200 ether);
    }

    function test_PauseUnpause() public {
        // 暂停市场
        vm.prank(owner);
        market.pause();
        
        // 尝试上架应该失败
        vm.prank(seller);
        vm.expectRevert();
        market.listNFT(address(nft), 1, NFT_PRICE);
        
        // 恢复市场
        vm.prank(owner);
        market.unpause();
        
        // 上架应该成功
        vm.prank(seller);
        market.listNFT(address(nft), 1, NFT_PRICE);
    }

    function test_EmergencyWithdraw() public {
        // 向市场合约发送一些 ETH
        vm.deal(address(market), 1 ether);
        
        uint256 initialOwnerBalance = owner.balance;
        
        vm.prank(owner);
        market.emergencyWithdraw(1 ether);
        
        assertEq(owner.balance, initialOwnerBalance + 1 ether, "Owner should receive withdrawn amount");
    }

    // ============ 升级准备测试 ============

    function test_UpgradeAuthorization() public {
        address newImplementation = makeAddr("newImplementation");
        
        // 非拥有者尝试升级应该失败
        vm.prank(seller);
        vm.expectRevert();
        market.upgradeToAndCall(newImplementation, "");
        
        // 拥有者可以授权升级（这里只测试授权逻辑，不实际升级）
        vm.prank(owner);
        // 注意：这里不实际执行升级，只验证授权逻辑存在
        // 实际升级需要新的实现合约
    }

    function test_SupportsInterface() public view {
        // 验证支持的接口
        assertTrue(market.supportsInterface(0x01ffc9a7), "Should support ERC165");
        // 其他接口测试可以在这里添加
    }

    // ============ 集成测试 ============

    function test_FullMarketWorkflow() public {
        uint256 tokenId = 1;
        
        // 1. 上架 NFT
        vm.prank(seller);
        market.listNFT(address(nft), tokenId, NFT_PRICE);
        
        // 2. 验证上架
        assertEq(market.activeListingsCount(), 1, "Should have 1 active listing");
        assertEq(nft.ownerOf(tokenId), address(market), "NFT should be in market");
        
        // 3. 购买 NFT
        bytes32[] memory userListings = market.getUserListings(seller);
        require(userListings.length > 0, "No listings found");
        bytes32 listingId = userListings[0];
        
        vm.prank(buyer);
        market.buyNFT{value: NFT_PRICE}(listingId);
        
        // 4. 验证购买结果
        assertEq(nft.ownerOf(tokenId), buyer, "Buyer should own NFT");
        assertEq(market.activeListingsCount(), 0, "Should have 0 active listings");
        
        // 5. 验证资金分配
        uint256 expectedFee = (NFT_PRICE * FEE_PERCENTAGE) / 10000;
        uint256 expectedSellerAmount = NFT_PRICE - expectedFee;
        
        assertEq(seller.balance, expectedSellerAmount, "Seller should receive correct amount");
        assertEq(feeRecipient.balance, expectedFee, "Fee recipient should receive fee");
    }

    function test_MultipleListings() public {
        // 铸造更多 NFT
        vm.prank(owner);
        nft.mint(seller);
        vm.prank(owner);
        nft.mint(seller);
        
        // 上架多个 NFT
        vm.prank(seller);
        market.listNFT(address(nft), 1, NFT_PRICE);
        vm.prank(seller);
        market.listNFT(address(nft), 2, NFT_PRICE * 2);
        vm.prank(seller);
        market.listNFT(address(nft), 3, NFT_PRICE * 3);
        
        // 验证活跃上架数量
        assertEq(market.activeListingsCount(), 3, "Should have 3 active listings");
        
        // 验证用户上架列表
        bytes32[] memory userListings = market.getUserListings(seller);
        assertEq(userListings.length, 3, "Seller should have 3 listings");
    }

    function test_GetMarketStats() public {
        // 向市场发送一些 ETH
        vm.deal(address(market), 5 ether);
        
        // 上架一个 NFT
        vm.prank(seller);
        market.listNFT(address(nft), 1, NFT_PRICE);
        
        // 获取市场统计
        (uint256 activeListings, uint256 contractBalance, uint256 feePercentage) = market.getMarketStats();
        
        assertEq(activeListings, 1, "Active listings should be 1");
        assertEq(contractBalance, 5 ether, "Contract balance should be 5 ether");
        assertEq(feePercentage, FEE_PERCENTAGE, "Fee percentage should match");
    }
}
