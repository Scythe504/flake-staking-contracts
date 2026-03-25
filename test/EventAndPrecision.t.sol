// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {StakingContract} from "../src/StakingContract.sol";
import {FlakeETH} from "../src/FlakeETH.sol";
import {FlakeToken} from "../src/FlakeToken.sol";
import {AchievementNFT} from "../src/AchievementNFT.sol";

contract EventAndPrecisionTest is Test {
    StakingContract stakeC;
    FlakeETH flakeEth;
    FlakeToken flake;
    AchievementNFT achievementNft;

    address user = vm.addr(1);

    // Re-declare events to test them (Foundry expects them in the test contract or a shared interface)
    event Staked(address indexed user, uint256 amount);
    event Unstaked(address indexed user, uint256 amount);
    event RewardsClaimed(address indexed user, uint256 amount);
    event AchievementEarned(address indexed user, uint256 indexed badgeId, uint256 indexed tokenId);

    function setUp() public {
        stakeC = new StakingContract();
        flakeEth = new FlakeETH(address(stakeC));
        flake = new FlakeToken(address(stakeC));
        achievementNft = new AchievementNFT(address(stakeC));
        stakeC.initialize(address(flakeEth), address(flake), address(achievementNft));
    }

    // --- EVENT TESTING ---

    function test_Emit_StakedEvent() public {
        uint256 amount = 1 ether;
        vm.deal(user, amount);
        
        // 1. Tell Foundry to expect a specific event
        // (checkTopic1, checkTopic2, checkTopic3, checkData)
        vm.expectEmit(true, false, false, true);
        
        // 2. Emit the expected event manually in the test
        emit Staked(user, amount);
        
        // 3. Trigger the actual call that should emit the event
        vm.prank(user);
        stakeC.stake{value: amount}(amount);
    }

    function test_Emit_UnstakedEvent() public {
        uint256 amount = 1 ether;
        vm.deal(user, amount);
        vm.prank(user);
        stakeC.stake{value: amount}(amount);

        vm.expectEmit(true, false, false, true);
        emit Unstaked(user, amount);

        vm.prank(user);
        stakeC.unstake(amount);
    }

    function test_Emit_RewardsClaimedEvent() public {
        uint256 amount = 1 ether;
        vm.deal(user, amount);
        vm.prank(user);
        stakeC.stake{value: amount}(amount);

        vm.roll(block.number + 100);
        uint256 rewards = stakeC.pendingRewards(user);

        vm.expectEmit(true, false, false, true);
        emit RewardsClaimed(user, rewards);

        vm.prank(user);
        stakeC.claimRewards();
    }

    function test_Emit_AchievementEarnedEvent() public {
        uint256 amount = 1 ether;
        vm.deal(user, amount);

        vm.expectEmit(true, true, true, true);
        emit AchievementEarned(user, 1, 0); // Genesis badge is ID 1, first token is ID 0

        vm.prank(user);
        stakeC.stake{value: amount}(amount);
    }

    // --- PRECISION & ROUNDING TESTING ---

    function test_Precision_SmallStakes() public {
        // rewardPerBlock = 1e14 (0.0001 tokens)
        // Math: (amount * blocks * 1e14) / 1e18
        // If amount = 1000 wei (tiny), and blocks = 1
        // (1000 * 1 * 1e14) / 1e18 = 1e17 / 1e18 = 0.1 -> Rounds to 0
        
        uint256 tinyAmount = 1000; 
        vm.deal(user, tinyAmount);
        vm.prank(user);
        stakeC.stake{value: tinyAmount}(tinyAmount);
        
        vm.roll(block.number + 1);
        uint256 rewards = stakeC.pendingRewards(user);
        
        assertEq(rewards, 0, "Tiny stakes should round down to 0 correctly");
        
        // Now wait enough blocks to earn at least 1 wei of reward
        // (1000 * blocks * 1e14) / 1e18 >= 1
        // blocks >= 1e18 / (1000 * 1e14) = 1e18 / 1e17 = 10
        vm.roll(block.number + 10);
        rewards = stakeC.pendingRewards(user);
        assertTrue(rewards >= 1, "Should eventually earn rewards even with tiny stake");
    }

    function test_Precision_ShortDuration() public {
        uint256 amount = 1 ether;
        vm.deal(user, amount);
        vm.prank(user);
        stakeC.stake{value: amount}(amount);
        
        // 1 block = (1e18 * 1 * 1e14) / 1e18 = 1e14
        vm.roll(block.number + 1);
        uint256 rewards = stakeC.pendingRewards(user);
        assertEq(rewards, 1e14, "Should earn exact reward for 1 block at 1 ETH");
    }
}
