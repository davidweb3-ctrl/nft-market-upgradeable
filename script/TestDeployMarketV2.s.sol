// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {NFTMarketUpgradeableV2} from "../src/NFTMarketUpgradeableV2.sol";

/**
 * @title TestDeployMarketV2
 * @dev 测试部署 NFTMarketUpgradeableV2 合约的脚本
 */
contract TestDeployMarketV2 is Script {
    function run() external {
        // 使用测试私钥
        uint256 deployerPrivateKey = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
        address deployer = vm.addr(deployerPrivateKey);
        address feeRecipient = deployer;
        
        console.log("Deploying NFTMarketUpgradeableV2...");
        console.log("Deployer address:", deployer);
        console.log("Deployer balance:", deployer.balance);

        // 开始广播交易
        vm.startBroadcast(deployerPrivateKey);

        // 部署 V2 实现合约
        NFTMarketUpgradeableV2 marketV2 = new NFTMarketUpgradeableV2();
        
        // 初始化合约
        marketV2.initialize(
            250, // 2.5% fee
            feeRecipient,
            0.001 ether, // min price
            100 ether    // max price
        );

        vm.stopBroadcast();

        // 输出部署信息
        console.log("NFTMarketUpgradeableV2 deployed at:", address(marketV2));
        console.log("Fee Percentage:", marketV2.feePercentage(), "bps");
        console.log("Fee Recipient:", marketV2.feeRecipient());
        console.log("Min Price:", marketV2.minPrice());
        console.log("Max Price:", marketV2.maxPrice());
        console.log("Owner:", marketV2.owner());
        console.log("Version:", marketV2.version());

        // 验证部署
        require(marketV2.owner() == deployer, "Owner not set correctly");
        require(marketV2.feePercentage() == 250, "Fee percentage not set correctly");
        require(marketV2.feeRecipient() == feeRecipient, "Fee recipient not set correctly");
        require(marketV2.minPrice() == 0.001 ether, "Min price not set correctly");
        require(marketV2.maxPrice() == 100 ether, "Max price not set correctly");
        require(keccak256(bytes(marketV2.version())) == keccak256(bytes("2.0.0")), "Version should be 2.0.0");

        console.log("V2 Deployment verification passed!");
    }
}
