// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {MyNFTUpgradeable} from "../src/MyNFTUpgradeable.sol";

/**
 * @title DeployMyNFT
 * @dev 部署 MyNFTUpgradeable 合约的脚本
 */
contract DeployMyNFT is Script {
    // 部署参数
    string constant NFT_NAME = "My Upgradeable NFT";
    string constant NFT_SYMBOL = "MUN";
    string constant BASE_URI = "https://api.mynft.com/metadata/";
    uint256 constant MAX_SUPPLY = 10000;

    function run() external {
        // 获取部署者私钥
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
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
            NFT_NAME,
            NFT_SYMBOL,
            BASE_URI,
            MAX_SUPPLY
        );

        vm.stopBroadcast();

        // 输出部署信息
        console.log("MyNFTUpgradeable deployed at:", address(nft));
        console.log("NFT Name:", NFT_NAME);
        console.log("NFT Symbol:", NFT_SYMBOL);
        console.log("Base URI:", BASE_URI);
        console.log("Max Supply:", MAX_SUPPLY);
        console.log("Owner:", nft.owner());
        console.log("Version:", nft.version());

        // 验证部署
        require(nft.owner() == deployer, "Owner not set correctly");
        require(nft.maxSupply() == MAX_SUPPLY, "Max supply not set correctly");
        require(nft.getCurrentTokenId() == 1, "Token ID counter not initialized correctly");
        require(nft.totalSupply() == 0, "Total supply should be 0 initially");

        console.log("Deployment verification passed!");
    }
}
