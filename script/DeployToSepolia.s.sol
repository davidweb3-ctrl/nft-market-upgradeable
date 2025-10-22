// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {MyNFTUpgradeable} from "../src/MyNFTUpgradeable.sol";
import {NFTMarketUpgradeable} from "../src/NFTMarketUpgradeable.sol";
import {NFTMarketUpgradeableV2} from "../src/NFTMarketUpgradeableV2.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

/**
 * @title DeployToSepolia
 * @dev 部署到Sepolia测试网的完整脚本
 */
contract DeployToSepolia is Script {
    // 部署参数
    string constant NFT_NAME = "My Upgradeable NFT";
    string constant NFT_SYMBOL = "MUN";
    string constant BASE_URI = "https://api.mynft.com/metadata/";
    uint256 constant MAX_SUPPLY = 10000;
    
    uint256 constant FEE_PERCENTAGE = 250; // 2.5%
    uint256 constant MIN_PRICE = 0.001 ether;
    uint256 constant MAX_PRICE = 100 ether;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        console.log("=== Deploying to Sepolia Testnet ===");
        console.log("Deployer:", deployer);
        console.log("Deployer balance:", deployer.balance);

        vm.startBroadcast(deployerPrivateKey);

        // 1. 部署NFT合约
        console.log("\n1. Deploying MyNFTUpgradeable...");
        MyNFTUpgradeable nft = new MyNFTUpgradeable();
        nft.initialize(NFT_NAME, NFT_SYMBOL, BASE_URI, MAX_SUPPLY);
        console.log("NFT Contract:", address(nft));

        // 2. 部署V1市场实现合约
        console.log("\n2. Deploying V1 Implementation...");
        NFTMarketUpgradeable v1Impl = new NFTMarketUpgradeable();
        console.log("V1 Implementation:", address(v1Impl));
        
        // 3. 准备V1初始化数据
        bytes memory initData = abi.encodeWithSelector(
            NFTMarketUpgradeable.initialize.selector,
            FEE_PERCENTAGE, 
            deployer, 
            MIN_PRICE, 
            MAX_PRICE
        );
        
        // 4. 部署V1 Proxy
        console.log("\n3. Deploying V1 Proxy...");
        ERC1967Proxy v1Proxy = new ERC1967Proxy(address(v1Impl), initData);
        console.log("V1 Proxy:", address(v1Proxy));
        
        // 5. 部署V2实现合约
        console.log("\n4. Deploying V2 Implementation...");
        NFTMarketUpgradeableV2 v2Impl = new NFTMarketUpgradeableV2();
        console.log("V2 Implementation:", address(v2Impl));
        
        // 6. 升级到V2
        console.log("\n5. Upgrading to V2...");
        NFTMarketUpgradeableV2 marketV2 = NFTMarketUpgradeableV2(address(v1Proxy));
        marketV2.upgradeToAndCall(address(v2Impl), "");
        
        // 7. 验证部署
        console.log("\n6. Deployment Complete!");
        console.log("NFT Contract:", address(nft));
        console.log("Market Proxy (V2):", address(v1Proxy));
        console.log("V1 Implementation:", address(v1Impl));
        console.log("V2 Implementation:", address(v2Impl));
        console.log("Version:", marketV2.version());
        console.log("Owner:", marketV2.owner());

        vm.stopBroadcast();

        // 最终验证
        require(keccak256(bytes(marketV2.version())) == keccak256(bytes("2.0.0")), "Version should be 2.0.0");
        require(marketV2.owner() == deployer, "Owner check failed");
        
        console.log("\n=== SUCCESS ===");
        console.log("All contracts deployed and upgraded successfully!");
    }
}
