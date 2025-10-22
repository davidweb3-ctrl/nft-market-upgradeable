// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {NFTMarketUpgradeableV2} from "../src/NFTMarketUpgradeableV2.sol";

/**
 * @title UpgradeToV2
 * @dev 升级现有的proxy到V2版本
 */
contract UpgradeToV2 is Script {
    // 现有的proxy地址
    address constant PROXY_ADDRESS = 0x5FC8d32690cc91D4c39d9d3abcBD16989F875707;

    function run() external {
        uint256 deployerPrivateKey = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
        address deployer = vm.addr(deployerPrivateKey);
        
        console.log("=== Upgrading Proxy to V2 ===");
        console.log("Deployer:", deployer);
        console.log("Proxy Address:", PROXY_ADDRESS);

        vm.startBroadcast(deployerPrivateKey);

        // 1. 部署新的V2实现合约
        console.log("\n1. Deploying V2 Implementation...");
        NFTMarketUpgradeableV2 v2Impl = new NFTMarketUpgradeableV2();
        console.log("V2 Implementation:", address(v2Impl));
        
        // 2. 升级proxy到V2
        console.log("\n2. Upgrading Proxy to V2...");
        NFTMarketUpgradeableV2 proxy = NFTMarketUpgradeableV2(PROXY_ADDRESS);
        proxy.upgradeToAndCall(address(v2Impl), "");
        
        // 3. 验证升级
        console.log("\n3. Upgrade Complete!");
        console.log("Version after upgrade:", proxy.version());
        console.log("Owner:", proxy.owner());
        
        // 测试V2新功能
        bytes32 hash = proxy.getSignatureHash(
            0x5FbDB2315678afecb367f032d93F642f64180aa3, 1, 1000000000000000000, 12345, 1735689600
        );
        console.log("V2 signature hash test:", vm.toString(hash));

        vm.stopBroadcast();

        // 最终验证
        require(keccak256(bytes(proxy.version())) == keccak256(bytes("2.0.0")), "Version should be 2.0.0");
        require(proxy.owner() == deployer, "Owner check failed");
        
        console.log("\n=== SUCCESS ===");
        console.log("Proxy (use this in frontend):", PROXY_ADDRESS);
        console.log("V2 Implementation:", address(v2Impl));
    }
}
