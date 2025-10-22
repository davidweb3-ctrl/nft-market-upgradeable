// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {NFTMarketUpgradeable} from "../src/NFTMarketUpgradeable.sol";
import {NFTMarketUpgradeableV2} from "../src/NFTMarketUpgradeableV2.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

/**
 * @title SimpleUpgradeTest
 * @dev 简化的UUPS升级测试脚本
 */
contract SimpleUpgradeTest is Script {
    uint256 constant FEE_PERCENTAGE = 250;
    uint256 constant MIN_PRICE = 0.001 ether;
    uint256 constant MAX_PRICE = 100 ether;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        console.log("=== Simple UUPS Upgrade Test ===");
        console.log("Deployer:", deployer);

        vm.startBroadcast(deployerPrivateKey);

        // 部署V1
        console.log("\n1. Deploying V1...");
        NFTMarketUpgradeable v1Impl = new NFTMarketUpgradeable();
        bytes memory initData = abi.encodeWithSelector(
            NFTMarketUpgradeable.initialize.selector,
            FEE_PERCENTAGE, deployer, MIN_PRICE, MAX_PRICE
        );
        ERC1967Proxy proxy = new ERC1967Proxy(address(v1Impl), initData);
        NFTMarketUpgradeable market = NFTMarketUpgradeable(address(proxy));
        
        console.log("V1 deployed at:", address(proxy));
        console.log("V1 version:", market.version());

        // 部署V2
        console.log("\n2. Deploying V2...");
        NFTMarketUpgradeableV2 v2Impl = new NFTMarketUpgradeableV2();
        console.log("V2 implementation:", address(v2Impl));

        // 升级
        console.log("\n3. Upgrading to V2...");
        market.upgradeToAndCall(address(v2Impl), "");
        
        // 验证
        console.log("\n4. Verifying upgrade...");
        NFTMarketUpgradeableV2 marketV2 = NFTMarketUpgradeableV2(address(proxy));
        console.log("V2 version:", marketV2.version());
        console.log("V2 owner:", marketV2.owner());
        
        // 测试V2功能
        bytes32 hash = marketV2.getSignatureHash(
            address(0x123), 1, 0.1 ether, 12345, block.timestamp + 3600
        );
        console.log("Signature hash generated:", vm.toString(hash));

        vm.stopBroadcast();

        // 最终验证
        require(keccak256(bytes(marketV2.version())) == keccak256(bytes("2.0.0")), "Version check failed");
        require(marketV2.owner() == deployer, "Owner check failed");
        
        console.log("\n[SUCCESS] Upgrade test completed!");
        console.log("Proxy:", address(proxy));
        console.log("V1 Impl:", address(v1Impl));
        console.log("V2 Impl:", address(v2Impl));
    }
}
