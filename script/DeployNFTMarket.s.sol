// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {NFTMarketUpgradeable} from "../src/NFTMarketUpgradeable.sol";

/**
 * @title DeployNFTMarket
 * @dev 部署 NFTMarketUpgradeable 合约的脚本
 */
contract DeployNFTMarket is Script {
    // 部署参数
    uint256 constant FEE_PERCENTAGE = 250; // 2.5%
    uint256 constant MIN_PRICE = 0.001 ether;
    uint256 constant MAX_PRICE = 100 ether;

    function run() external {
        // 获取部署者私钥
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        address feeRecipient = deployer; // 使用部署者作为手续费接收者
        
        console.log("Deploying NFTMarketUpgradeable...");
        console.log("Deployer address:", deployer);
        console.log("Deployer balance:", deployer.balance);
        console.log("Fee recipient:", feeRecipient);

        // 开始广播交易
        vm.startBroadcast(deployerPrivateKey);

        // 部署实现合约
        NFTMarketUpgradeable market = new NFTMarketUpgradeable();
        
        // 初始化合约
        market.initialize(
            FEE_PERCENTAGE,
            feeRecipient,
            MIN_PRICE,
            MAX_PRICE
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
        require(market.feePercentage() == FEE_PERCENTAGE, "Fee percentage not set correctly");
        require(market.feeRecipient() == feeRecipient, "Fee recipient not set correctly");
        require(market.minPrice() == MIN_PRICE, "Min price not set correctly");
        require(market.maxPrice() == MAX_PRICE, "Max price not set correctly");

        console.log("Deployment verification passed!");
    }
}
