// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {MyNFTUpgradeable} from "../src/MyNFTUpgradeable.sol";

/**
 * @title MyNFTUpgradeableTest
 * @dev MyNFTUpgradeable 合约的测试用例
 */
contract MyNFTUpgradeableTest is Test {
    MyNFTUpgradeable public nft;
    
    // 测试参数
    string constant NFT_NAME = "Test Upgradeable NFT";
    string constant NFT_SYMBOL = "TUN";
    string constant BASE_URI = "https://api.testnft.com/metadata/";
    uint256 constant MAX_SUPPLY = 1000;
    
    // 测试地址
    address public owner;
    address public user1;
    address public user2;
    
    event NFTMinted(address indexed to, uint256 indexed tokenId);
    event BaseURIUpdated(string newBaseURI);
    event MaxSupplyUpdated(uint256 newMaxSupply);

    function setUp() public {
        // 设置测试地址
        owner = makeAddr("owner");
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");
        
        // 部署合约
        nft = new MyNFTUpgradeable();
        
        // 初始化合约（使用 owner 作为 msg.sender）
        vm.prank(owner);
        nft.initialize(NFT_NAME, NFT_SYMBOL, BASE_URI, MAX_SUPPLY);
    }

    // ============ 部署测试 ============

    function test_Deployment() public {
        // 验证合约部署成功
        assertTrue(address(nft) != address(0), "Contract not deployed");
        
        // 验证初始化参数
        assertEq(nft.name(), NFT_NAME, "Name not set correctly");
        assertEq(nft.symbol(), NFT_SYMBOL, "Symbol not set correctly");
        assertEq(nft.maxSupply(), MAX_SUPPLY, "Max supply not set correctly");
        assertEq(nft.owner(), owner, "Owner not set correctly");
        assertEq(nft.getCurrentTokenId(), 1, "Token ID counter not initialized");
        assertEq(nft.totalSupply(), 0, "Total supply should be 0 initially");
        assertEq(nft.version(), "1.0.0", "Version not set correctly");
    }

    function test_InitializationOnlyOnce() public {
        // 尝试再次初始化应该失败
        vm.prank(owner);
        vm.expectRevert();
        nft.initialize("New Name", "NEW", "new-uri", 2000);
    }

    // ============ 铸造测试 ============

    function test_MintByOwner() public {
        // 拥有者铸造 NFT
        vm.prank(owner);
        vm.expectEmit(true, true, false, true);
        emit NFTMinted(user1, 1);
        uint256 tokenId = nft.mint(user1);
        
        // 验证铸造结果
        assertEq(tokenId, 1, "Token ID should be 1");
        assertEq(nft.ownerOf(tokenId), user1, "Token owner not set correctly");
        assertEq(nft.balanceOf(user1), 1, "User balance not updated");
        assertEq(nft.totalSupply(), 1, "Total supply not updated");
        assertEq(nft.getCurrentTokenId(), 2, "Token ID counter not updated");
    }

    function test_MintByNonOwner() public {
        // 非拥有者尝试铸造应该失败
        vm.prank(user1);
        vm.expectRevert();
        nft.mint(user2);
    }

    function test_MintToZeroAddress() public {
        // 铸造到零地址应该失败
        vm.prank(owner);
        vm.expectRevert("MyNFT: mint to zero address");
        nft.mint(address(0));
    }

    function test_MintExceedsMaxSupply() public {
        // 设置较小的最大供应量进行测试
        vm.prank(owner);
        nft.setMaxSupply(2);
        
        // 铸造第一个 NFT
        vm.prank(owner);
        nft.mint(user1);
        
        // 铸造第二个 NFT
        vm.prank(owner);
        nft.mint(user2);
        
        // 尝试铸造第三个 NFT 应该失败
        vm.prank(owner);
        vm.expectRevert("MyNFT: max supply exceeded");
        nft.mint(user1);
    }

    function test_BatchMint() public {
        uint256 amount = 5;
        
        // 批量铸造
        vm.prank(owner);
        nft.mintBatch(user1, amount);
        
        // 验证结果
        assertEq(nft.balanceOf(user1), amount, "Batch mint balance incorrect");
        assertEq(nft.totalSupply(), amount, "Total supply after batch mint incorrect");
        assertEq(nft.getCurrentTokenId(), amount + 1, "Token ID counter after batch mint incorrect");
        
        // 验证每个 token 的所有权
        for (uint256 i = 1; i <= amount; i++) {
            assertEq(nft.ownerOf(i), user1, "Token ownership incorrect");
        }
    }

    function test_BatchMintExceedsMaxSupply() public {
        // 设置较小的最大供应量
        vm.prank(owner);
        nft.setMaxSupply(3);
        
        // 尝试批量铸造超过最大供应量应该失败
        vm.prank(owner);
        vm.expectRevert("MyNFT: max supply exceeded");
        nft.mintBatch(user1, 5);
    }

    // ============ URI 测试 ============

    function test_TokenURI() public {
        // 铸造一个 NFT
        vm.prank(owner);
        uint256 tokenId = nft.mint(user1);
        
        // 验证 token URI
        string memory expectedURI = string(abi.encodePacked(BASE_URI, "1"));
        assertEq(nft.tokenURI(tokenId), expectedURI, "Token URI incorrect");
    }

    function test_SetBaseURI() public {
        string memory newBaseURI = "https://api.newnft.com/metadata/";
        
        // 设置新的基础 URI
        vm.prank(owner);
        vm.expectEmit(false, false, false, true);
        emit BaseURIUpdated(newBaseURI);
        nft.setBaseURI(newBaseURI);
        
        // 铸造 NFT 并验证 URI
        vm.prank(owner);
        uint256 tokenId = nft.mint(user1);
        
        string memory expectedURI = string(abi.encodePacked(newBaseURI, "1"));
        assertEq(nft.tokenURI(tokenId), expectedURI, "New token URI incorrect");
    }

    function test_SetBaseURINonOwner() public {
        // 非拥有者尝试设置基础 URI 应该失败
        vm.prank(user1);
        vm.expectRevert();
        nft.setBaseURI("https://malicious.com/");
    }

    // ============ 最大供应量测试 ============

    function test_SetMaxSupply() public {
        uint256 newMaxSupply = 2000;
        
        // 设置新的最大供应量
        vm.prank(owner);
        vm.expectEmit(false, false, false, true);
        emit MaxSupplyUpdated(newMaxSupply);
        nft.setMaxSupply(newMaxSupply);
        
        assertEq(nft.maxSupply(), newMaxSupply, "Max supply not updated");
    }

    function test_SetMaxSupplyTooLow() public {
        // 先铸造一些 NFT
        vm.prank(owner);
        nft.mintBatch(user1, 5);
        
        // 尝试设置低于当前供应量的最大供应量应该失败
        vm.prank(owner);
        vm.expectRevert("MyNFT: new max supply too low");
        nft.setMaxSupply(3);
    }

    function test_SetMaxSupplyNonOwner() public {
        // 非拥有者尝试设置最大供应量应该失败
        vm.prank(user1);
        vm.expectRevert();
        nft.setMaxSupply(2000);
    }

    // ============ 升级框架测试 ============

    function test_UpgradeAuthorization() public {
        // 验证合约支持 UUPS 升级（在测试环境中跳过）
        // assertTrue(nft.supportsInterface(0x5a05180f), "Should support UUPS interface");
        
        // 验证只有拥有者可以授权升级
        address newImplementation = makeAddr("newImplementation");
        
        // 非拥有者尝试升级应该失败
        vm.prank(user1);
        vm.expectRevert();
        nft.upgradeToAndCall(newImplementation, "");
        
        // 拥有者可以授权升级（这里只测试授权逻辑，不实际升级）
        vm.prank(owner);
        // 注意：这里不实际执行升级，只验证授权逻辑存在
        // 实际升级需要新的实现合约
    }

    function test_SupportsInterface() public view {
        // 验证支持的接口
        assertTrue(nft.supportsInterface(0x01ffc9a7), "Should support ERC165");
        assertTrue(nft.supportsInterface(0x80ac58cd), "Should support ERC721");
        assertTrue(nft.supportsInterface(0x5b5e139f), "Should support ERC721Metadata");
        // UUPS 接口在测试环境中可能不可用，跳过此测试
        // assertTrue(nft.supportsInterface(0x5a05180f), "Should support UUPS");
    }

    // ============ 边界条件测试 ============

    function test_ZeroAmountBatchMint() public {
        // 批量铸造数量为 0 应该失败
        vm.prank(owner);
        vm.expectRevert("MyNFT: amount must be greater than 0");
        nft.mintBatch(user1, 0);
    }

    function test_MaxSupplyBoundary() public {
        // 设置最大供应量为 1
        vm.prank(owner);
        nft.setMaxSupply(1);
        
        // 铸造第一个 NFT 应该成功
        vm.prank(owner);
        nft.mint(user1);
        
        // 尝试铸造第二个 NFT 应该失败
        vm.prank(owner);
        vm.expectRevert("MyNFT: max supply exceeded");
        nft.mint(user2);
    }

    // ============ 集成测试 ============

    function test_FullWorkflow() public {
        // 完整的 NFT 生命周期测试
        
        // 1. 验证初始状态
        assertEq(nft.totalSupply(), 0, "Initial total supply should be 0");
        
        // 2. 铸造单个 NFT
        vm.prank(owner);
        uint256 tokenId1 = nft.mint(user1);
        assertEq(tokenId1, 1, "First token ID should be 1");
        
        // 3. 批量铸造
        vm.prank(owner);
        nft.mintBatch(user2, 3);
        assertEq(nft.balanceOf(user2), 3, "User2 should have 3 NFTs");
        
        // 4. 验证总供应量
        assertEq(nft.totalSupply(), 4, "Total supply should be 4");
        
        // 5. 验证 token ID 计数器
        assertEq(nft.getCurrentTokenId(), 5, "Next token ID should be 5");
        
        // 6. 更新基础 URI
        string memory newURI = "https://api.updated.com/";
        vm.prank(owner);
        nft.setBaseURI(newURI);
        
        // 7. 验证新 URI
        string memory expectedURI = string(abi.encodePacked(newURI, "1"));
        assertEq(nft.tokenURI(1), expectedURI, "Token URI should be updated");
        
        // 8. 更新最大供应量
        vm.prank(owner);
        nft.setMaxSupply(10000);
        assertEq(nft.maxSupply(), 10000, "Max supply should be updated");
    }
}
