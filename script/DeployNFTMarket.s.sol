// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {NFTMarketUpgradeable} from "../src/NFTMarketUpgradeable.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

/**
 * @title DeployNFTMarket
 * @dev 使用UUPS代理模式部署 NFTMarketUpgradeable 合约
 */
contract DeployNFTMarket is Script {
    // 部署参数
    uint256 constant FEE_PERCENTAGE = 250; // 2.5%
    uint256 constant MIN_PRICE = 0.001 ether;
    uint256 constant MAX_PRICE = 100 ether;

    function run() external {
        // 获取部署者私钥
        uint256 deployerPrivateKey = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
        address deployer = vm.addr(deployerPrivateKey);
        address feeRecipient = deployer; // 使用部署者作为手续费接收者
        
        console.log("Deploying NFTMarketUpgradeable with UUPS Proxy...");
        console.log("Deployer address:", deployer);
        console.log("Deployer balance:", deployer.balance);
        console.log("Fee recipient:", feeRecipient);

        // 开始广播交易
        vm.startBroadcast(deployerPrivateKey);

        // 1. 部署实现合约
        NFTMarketUpgradeable implementation = new NFTMarketUpgradeable();
        console.log("Implementation deployed at:", address(implementation));

        // 2. 准备初始化数据
        bytes memory initData = abi.encodeWithSelector(
            NFTMarketUpgradeable.initialize.selector,
            FEE_PERCENTAGE,
            feeRecipient,
            MIN_PRICE,
            MAX_PRICE
        );

        // 3. 部署代理合约
        ERC1967Proxy proxy = new ERC1967Proxy(address(implementation), initData);
        console.log("Proxy deployed at:", address(proxy));

        // 4. 通过代理地址创建合约实例
        NFTMarketUpgradeable market = NFTMarketUpgradeable(address(proxy));

        vm.stopBroadcast();

        // 输出部署信息
        console.log("=== Deployment Summary ===");
        console.log("Proxy Address (use this):", address(proxy));
        console.log("Implementation Address:", address(implementation));
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
        console.log("Contract is now upgradeable via UUPS!");
    }
}
