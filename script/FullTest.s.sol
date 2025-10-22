// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {MyNFTUpgradeable} from "../src/MyNFTUpgradeable.sol";
import {NFTMarketUpgradeable} from "../src/NFTMarketUpgradeable.sol";
import {NFTMarketUpgradeableV2} from "../src/NFTMarketUpgradeableV2.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

/**
 * @title FullTest
 * @dev 完整的UUPS部署和升级测试脚本
 */
contract FullTest is Script {
    uint256 constant FEE_PERCENTAGE = 250;
    uint256 constant MIN_PRICE = 0.001 ether;
    uint256 constant MAX_PRICE = 100 ether;
    string constant NFT_NAME = "Test NFT";
    string constant NFT_SYMBOL = "TNFT";
    string constant BASE_URI = "https://api.test.com/";

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        console.log("=== Full UUPS Test Suite ===");
        console.log("Deployer:", deployer);

        vm.startBroadcast(deployerPrivateKey);

        // === 1. 部署NFT合约 ===
        console.log("\n=== 1. Deploying NFT Contract ===");
        MyNFTUpgradeable nftImpl = new MyNFTUpgradeable();
        bytes memory nftInitData = abi.encodeWithSelector(
            MyNFTUpgradeable.initialize.selector,
            NFT_NAME, NFT_SYMBOL, BASE_URI, 1000
        );
        ERC1967Proxy nftProxy = new ERC1967Proxy(address(nftImpl), nftInitData);
        MyNFTUpgradeable nft = MyNFTUpgradeable(address(nftProxy));
        
        console.log("NFT Proxy:", address(nftProxy));
        console.log("NFT Implementation:", address(nftImpl));
        console.log("NFT Version:", nft.version());

        // === 2. 部署市场合约V1 ===
        console.log("\n=== 2. Deploying Market V1 ===");
        NFTMarketUpgradeable marketV1Impl = new NFTMarketUpgradeable();
        bytes memory marketInitData = abi.encodeWithSelector(
            NFTMarketUpgradeable.initialize.selector,
            FEE_PERCENTAGE, deployer, MIN_PRICE, MAX_PRICE
        );
        ERC1967Proxy marketProxy = new ERC1967Proxy(address(marketV1Impl), marketInitData);
        NFTMarketUpgradeable market = NFTMarketUpgradeable(address(marketProxy));
        
        console.log("Market Proxy:", address(marketProxy));
        console.log("Market V1 Implementation:", address(marketV1Impl));
        console.log("Market Version:", market.version());

        // === 3. 测试NFT功能 ===
        console.log("\n=== 3. Testing NFT Functions ===");
        nft.mint(deployer);
        console.log("NFT minted, total supply:", nft.totalSupply());
        console.log("NFT owner of token 1:", nft.ownerOf(1));

        // === 4. 测试市场V1功能 ===
        console.log("\n=== 4. Testing Market V1 Functions ===");
        nft.approve(address(market), 1);
        market.listNFT(address(nft), 1, 0.1 ether);
        console.log("NFT listed on market");
        console.log("Active listings:", market.activeListingsCount());

        // === 5. 升级到V2 ===
        console.log("\n=== 5. Upgrading to V2 ===");
        NFTMarketUpgradeableV2 marketV2Impl = new NFTMarketUpgradeableV2();
        market.upgradeToAndCall(address(marketV2Impl), "");
        
        NFTMarketUpgradeableV2 marketV2 = NFTMarketUpgradeableV2(address(marketProxy));
        console.log("Market V2 Implementation:", address(marketV2Impl));
        console.log("Market Version after upgrade:", marketV2.version());

        // === 6. 测试V2新功能 ===
        console.log("\n=== 6. Testing V2 New Features ===");
        bytes32 hash = marketV2.getSignatureHash(
            address(nft), 1, 0.2 ether, 12345, block.timestamp + 3600
        );
        console.log("Signature hash generated:", vm.toString(hash));

        // === 7. 验证数据完整性 ===
        console.log("\n=== 7. Verifying Data Integrity ===");
        console.log("Active listings after upgrade:", marketV2.activeListingsCount());
        console.log("Fee percentage:", marketV2.feePercentage());
        console.log("Owner:", marketV2.owner());

        vm.stopBroadcast();

        // === 最终验证 ===
        require(keccak256(bytes(marketV2.version())) == keccak256(bytes("2.0.0")), "Version check failed");
        require(marketV2.owner() == deployer, "Owner check failed");
        require(marketV2.activeListingsCount() == 1, "Listing count check failed");
        
        console.log("\n[SUCCESS] Full test completed successfully!");
        console.log("NFT Proxy:", address(nftProxy));
        console.log("Market Proxy:", address(marketProxy));
        console.log("V1 Implementation:", address(marketV1Impl));
        console.log("V2 Implementation:", address(marketV2Impl));
    }
}
