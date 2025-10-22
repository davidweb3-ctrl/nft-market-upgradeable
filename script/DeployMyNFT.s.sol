// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {MyNFTUpgradeable} from "../src/MyNFTUpgradeable.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

/**
 * @title DeployMyNFT
 * @dev 使用UUPS代理模式部署 MyNFTUpgradeable 合约
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
        
        console.log("Deploying MyNFTUpgradeable with UUPS Proxy...");
        console.log("Deployer address:", deployer);
        console.log("Deployer balance:", deployer.balance);

        // 开始广播交易
        vm.startBroadcast(deployerPrivateKey);

        // 1. 部署实现合约
        MyNFTUpgradeable implementation = new MyNFTUpgradeable();
        console.log("Implementation deployed at:", address(implementation));

        // 2. 准备初始化数据
        bytes memory initData = abi.encodeWithSelector(
            MyNFTUpgradeable.initialize.selector,
            NFT_NAME,
            NFT_SYMBOL,
            BASE_URI,
            MAX_SUPPLY
        );

        // 3. 部署代理合约
        ERC1967Proxy proxy = new ERC1967Proxy(address(implementation), initData);
        console.log("Proxy deployed at:", address(proxy));

        // 4. 通过代理地址创建合约实例
        MyNFTUpgradeable nft = MyNFTUpgradeable(address(proxy));

        vm.stopBroadcast();

        // 输出部署信息
        console.log("=== Deployment Summary ===");
        console.log("Proxy Address (use this):", address(proxy));
        console.log("Implementation Address:", address(implementation));
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
        console.log("Contract is now upgradeable via UUPS!");
    }
}
