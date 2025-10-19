// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {NFTMarketUpgradeable} from "../src/NFTMarketUpgradeable.sol";

/**
 * @title TestDeployMarket
 * @dev 测试部署 NFTMarketUpgradeable 合约的脚本
 */
contract TestDeployMarket is Script {
    function run() external {
        // 使用测试私钥
        uint256 deployerPrivateKey = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
        address deployer = vm.addr(deployerPrivateKey);
        address feeRecipient = deployer;
        
        console.log("Deploying NFTMarketUpgradeable...");
        console.log("Deployer address:", deployer);
        console.log("Deployer balance:", deployer.balance);

        // 开始广播交易
        vm.startBroadcast(deployerPrivateKey);

        // 部署实现合约
        NFTMarketUpgradeable market = new NFTMarketUpgradeable();
        
        // 初始化合约
        market.initialize(
            250, // 2.5% fee
            feeRecipient,
            0.001 ether, // min price
            100 ether    // max price
        );

        vm.stopBroadcast();

        // 输出部署信息
        console.log("NFTMarketUpgradeable deployed at:", address(market));
        console.log("Fee Percentage:", market.feePercentage(), "bps");
        console.log("Fee Recipient:", market.feeRecipient());
        console.log("Min Price:", market.minPrice());
        console.log("Max Price:", market.maxPrice());
        console.log("Owner:", market.owner());
        console.log("Version:", market.version());

        // 验证部署
        require(market.owner() == deployer, "Owner not set correctly");
        require(market.feePercentage() == 250, "Fee percentage not set correctly");
        require(market.feeRecipient() == feeRecipient, "Fee recipient not set correctly");
        require(market.minPrice() == 0.001 ether, "Min price not set correctly");
        require(market.maxPrice() == 100 ether, "Max price not set correctly");

        console.log("Deployment verification passed!");
    }
}
