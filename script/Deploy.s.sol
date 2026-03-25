// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {StakingContract} from "../src/StakingContract.sol";
import {FlakeETH} from "../src/FlakeETH.sol";
import {FlakeToken} from "../src/FlakeToken.sol";
import {AchievementNFT} from "../src/AchievementNFT.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract DeployScript is Script {
    function run() external {
        // Deployer is the one running the script (vm.startBroadcast uses the --private-key flag)
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        console.log("Deploying from address:", deployer);
        
        vm.startBroadcast(deployerPrivateKey);

        // 1. Deploy Implementation
        StakingContract implementation = new StakingContract();
        console.log("Implementation deployed at:", address(implementation));

        // 2. Predict the Proxy address
        // After implementation (nonce X):
        // X: FlakeETH
        // X+1: FlakeToken
        // X+2: AchievementNFT
        // X+3: setBadgeCID 1
        // X+4: setBadgeCID 2
        // X+5: setBadgeCID 3
        // X+6: Proxy
        uint64 nonce = vm.getNonce(deployer);
        address predictedProxy = vm.computeCreateAddress(deployer, nonce + 6);

        // 3. Deploy Tokens with predicted proxy as minter
        FlakeETH flakeEth = new FlakeETH(predictedProxy);
        FlakeToken flake = new FlakeToken(predictedProxy);
        AchievementNFT achievementNft = new AchievementNFT(predictedProxy);

        console.log("FlakeETH deployed at:", address(flakeEth));
        console.log("FlakeToken deployed at:", address(flake));
        console.log("AchievementNFT deployed at:", address(achievementNft));

        // 4. Set Achievement CIDs
        achievementNft.setBadgeCID(1, "bafybeiaie3uckv6vjp3jv6sebpkzt5udpe7kckbdwqrfid4ncs5u5h6w4y"); // Genesis
        achievementNft.setBadgeCID(2, "bafybeicgqoi6udhnc2zrwi4tlhaqxhqv6melf5y5brfbmradjqrmnnoexe"); // Whale
        achievementNft.setBadgeCID(3, "bafybeibnyqak7cejzw6dat3l5q5tixqu3hyweboobon4t23ee75vsv4x3a"); // Diamond Hands
        console.log("Achievement CIDs configured");

        // 5. Deploy Proxy pointing to the implementation and initializing with tokens
        bytes memory initData = abi.encodeWithSelector(
            StakingContract.initialize.selector,
            address(flakeEth),
            address(flake),
            address(achievementNft)
        );
        ERC1967Proxy proxy = new ERC1967Proxy(address(implementation), initData);

        console.log("Proxy deployed at:", address(proxy));
        console.log("Predicted Proxy matched:", predictedProxy == address(proxy));

        vm.stopBroadcast();
    }
}
