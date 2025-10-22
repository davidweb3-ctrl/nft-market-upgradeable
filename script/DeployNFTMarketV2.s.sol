// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {NFTMarketUpgradeableV2} from "../src/NFTMarketUpgradeableV2.sol";

/**
 * @title DeployNFTMarketV2
 * @dev 部署 NFTMarketUpgradeableV2 合约的脚本
 */
contract DeployNFTMarketV2 is Script {
    // 部署参数
    uint256 constant FEE_PERCENTAGE = 250; // 2.5%
    uint256 constant MIN_PRICE = 0.001 ether;
    uint256 constant MAX_PRICE = 100 ether;

    function run() external {
        // 获取部署者私钥
        uint256 deployerPrivateKey = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
        address deployer = vm.addr(deployerPrivateKey);
        address feeRecipient = deployer; // 使用部署者作为手续费接收者
        
        console.log("Deploying NFTMarketUpgradeableV2...");
        console.log("Deployer address:", deployer);
        console.log("Deployer balance:", deployer.balance);
        console.log("Fee recipient:", feeRecipient);

        // 开始广播交易
        vm.startBroadcast(deployerPrivateKey);

        // 部署 V2 实现合约
        NFTMarketUpgradeableV2 marketV2 = new NFTMarketUpgradeableV2();
        
        // 初始化合约
        marketV2.initialize(
            FEE_PERCENTAGE,
            feeRecipient,
            MIN_PRICE,
            MAX_PRICE
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
        require(marketV2.feePercentage() == FEE_PERCENTAGE, "Fee percentage not set correctly");
        require(marketV2.feeRecipient() == feeRecipient, "Fee recipient not set correctly");
        require(marketV2.minPrice() == MIN_PRICE, "Min price not set correctly");
        require(marketV2.maxPrice() == MAX_PRICE, "Max price not set correctly");
        require(keccak256(bytes(marketV2.version())) == keccak256(bytes("2.0.0")), "Version should be 2.0.0");

        console.log("V2 Deployment verification passed!");
    }
}
