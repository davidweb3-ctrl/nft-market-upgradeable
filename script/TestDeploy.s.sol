// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {MyNFTUpgradeable} from "../src/MyNFTUpgradeable.sol";

/**
 * @title TestDeploy
 * @dev 测试部署 MyNFTUpgradeable 合约的脚本
 */
contract TestDeploy is Script {
    function run() external {
        // 使用测试私钥
        uint256 deployerPrivateKey = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
        address deployer = vm.addr(deployerPrivateKey);
        
        console.log("Deploying MyNFTUpgradeable...");
        console.log("Deployer address:", deployer);
        console.log("Deployer balance:", deployer.balance);

        // 开始广播交易
        vm.startBroadcast(deployerPrivateKey);

        // 部署实现合约
        MyNFTUpgradeable nft = new MyNFTUpgradeable();
        
        // 初始化合约
        nft.initialize(
            "My Upgradeable NFT",
            "MUN",
            "https://api.mynft.com/metadata/",
            10000
        );

        vm.stopBroadcast();

        // 输出部署信息
        console.log("MyNFTUpgradeable deployed at:", address(nft));
        console.log("NFT Name:", nft.name());
        console.log("NFT Symbol:", nft.symbol());
        console.log("Max Supply:", nft.maxSupply());
        console.log("Owner:", nft.owner());
        console.log("Version:", nft.version());

        // 验证部署
        require(nft.owner() == deployer, "Owner not set correctly");
        require(nft.maxSupply() == 10000, "Max supply not set correctly");
        require(nft.getCurrentTokenId() == 1, "Token ID counter not initialized correctly");
        require(nft.totalSupply() == 0, "Total supply should be 0 initially");

        console.log("Deployment verification passed!");
    }
}
