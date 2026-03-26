// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {StakingContract} from "../src/StakingContract.sol";
import {FlakeETH} from "../src/FlakeETH.sol";
import {AchievementNFT} from "../src/AchievementNFT.sol";

contract FinalUpgradeScript is Script {
    function run() external {
        uint256 pk = vm.envUint("PRIVATE_KEY");
        address proxyAddr = vm.envAddress("PROXY_ADDRESS");
        address deployer = vm.addr(pk);

        vm.startBroadcast(pk);

        // 1. Deploy the NEW Staking Logic (The one with setTokenAddresses)
        StakingContract newImpl = new StakingContract();
        console.log("New Implementation deployed at:", address(newImpl));

        // 2. Deploy the new Soulbound Tokens
        // Passing proxyAddr so they grant it MINTER_ROLE immediately
        FlakeETH newSbEth = new FlakeETH(proxyAddr);
        AchievementNFT newFach = new AchievementNFT(proxyAddr);
        
        console.log("New Soulbound ETH:", address(newSbEth));
        console.log("New Achievement NFT:", address(newFach));

        // 3. Perform the UUPS Upgrade
        // We use the creator wallet (0x884c...) to point the Proxy to the New Implementation
        StakingContract proxy = StakingContract(proxyAddr);
        
        // This line updates the code inside the Proxy so it "learns" the setTokenAddresses function
        proxy.upgradeToAndCall(address(newImpl), "");
        console.log("Proxy logic upgraded successfully.");

        // 4. Configure the new NFT
        newFach.setBadgeCID(1, "bafybeiaie3uckv6vjp3jv6sebpkzt5udpe7kckbdwqrfid4ncs5u5h6w4y");
        newFach.setBadgeCID(2, "bafybeicgqoi6udhnc2zrwi4tlhaqxhqv6melf5y5brfbmradjqrmnnoexe");
        newFach.setBadgeCID(3, "bafybeibnyqak7cejzw6dat3l5q5tixqu3hyweboobon4t23ee75vsv4x3a");

        // 5. Finally, swap the token addresses
        // Note: If this still reverts, you MUST grant the OWNER role first (see below)
        proxy.setTokenAddresses(
            address(newSbEth),
            address(proxy.flake()), 
            address(newFach)
        );

        console.log("System Sync Complete!");
        vm.stopBroadcast();
    }
}