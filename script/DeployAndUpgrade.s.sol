// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {NFTMarketUpgradeable} from "../src/NFTMarketUpgradeable.sol";
import {NFTMarketUpgradeableV2} from "../src/NFTMarketUpgradeableV2.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

/**
 * @title DeployAndUpgrade
 * @dev 部署市场 V1 + Proxy，然后升级到 V2
 */
contract DeployAndUpgrade is Script {
    uint256 constant FEE_PERCENTAGE = 250;
    uint256 constant MIN_PRICE = 0.001 ether;
    uint256 constant MAX_PRICE = 100 ether;

    function run() external {
        uint256 deployerPrivateKey = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
        address deployer = vm.addr(deployerPrivateKey);
        
        console.log("=== Deploy Market V1 + Proxy, then Upgrade to V2 ===");
        console.log("Deployer:", deployer);

        vm.startBroadcast(deployerPrivateKey);

        // 1. 部署 V1 实现合约
        console.log("\n1. Deploying V1 Implementation...");
        NFTMarketUpgradeable v1Impl = new NFTMarketUpgradeable();
        console.log("V1 Implementation:", address(v1Impl));
        
        // 2. 准备初始化数据
        bytes memory initData = abi.encodeWithSelector(
            NFTMarketUpgradeable.initialize.selector,
            FEE_PERCENTAGE, 
            deployer, 
            MIN_PRICE, 
            MAX_PRICE
        );
        
        // 3. 部署 Proxy
        console.log("\n2. Deploying Proxy...");
        ERC1967Proxy proxy = new ERC1967Proxy(address(v1Impl), initData);
        console.log("Proxy Address:", address(proxy));
        
        // 4. 通过 Proxy 访问市场合约
        NFTMarketUpgradeable market = NFTMarketUpgradeable(address(proxy));
        console.log("\n3. Market V1 deployed via Proxy");
        console.log("Version:", market.version());
        console.log("Owner:", market.owner());
        console.log("Fee Percentage:", market.feePercentage());
        
        // 5. 部署 V2 实现合约
        console.log("\n4. Deploying V2 Implementation...");
        NFTMarketUpgradeableV2 v2Impl = new NFTMarketUpgradeableV2();
        console.log("V2 Implementation:", address(v2Impl));
        
        // 6. 升级到 V2
        console.log("\n5. Upgrading Proxy to V2...");
        market.upgradeToAndCall(address(v2Impl), "");
        
        // 7. 验证升级
        NFTMarketUpgradeableV2 marketV2 = NFTMarketUpgradeableV2(address(proxy));
        console.log("\n6. Upgrade Complete!");
        console.log("Version after upgrade:", marketV2.version());
        console.log("Owner:", marketV2.owner());
        
        // 测试 V2 新功能
        bytes32 hash = marketV2.getSignatureHash(
            address(0x123), 1, 0.1 ether, 12345, block.timestamp + 3600
        );
        console.log("V2 signature hash test:", vm.toString(hash));

        vm.stopBroadcast();

        // 最终验证
        require(keccak256(bytes(marketV2.version())) == keccak256(bytes("2.0.0")), "Version should be 2.0.0");
        require(marketV2.owner() == deployer, "Owner check failed");
        
        console.log("\n=== SUCCESS ===");
        console.log("Proxy (use this in frontend):", address(proxy));
        console.log("V1 Implementation:", address(v1Impl));
        console.log("V2 Implementation:", address(v2Impl));
    }
}
