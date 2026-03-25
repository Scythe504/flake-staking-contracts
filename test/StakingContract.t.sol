// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {StakingContract} from "../src/StakingContract.sol";
import {FlakeETH} from "../src/FlakeETH.sol";
import {FlakeToken} from "../src/FlakeToken.sol";
import {AchievementNFT} from "../src/AchievementNFT.sol";

contract StakingContractTest is Test {
    StakingContract stakeC;
    address user = vm.addr(1);
    address addrC;
    FlakeETH flakeEth;
    FlakeToken flake;
    AchievementNFT achievementNft;

    function setUp() public {
        stakeC = new StakingContract();
        flakeEth = new FlakeETH(address(stakeC));
        flake = new FlakeToken(address(stakeC));
        achievementNft = new AchievementNFT(address(stakeC));
        stakeC.initialize(
            address(flakeEth),
            address(flake),
            address(achievementNft)
        );
        addrC = address(this);
    }

    function _stakeAs(address addr, uint256 amount) internal {
        vm.deal(addr, amount);
        vm.prank(addr);
        stakeC.stake{value: amount}(amount);
    }

    // ---setRewardPerBlock---
    function test_SetRewardRateSuccess() public {
        uint256 rewardRate = 1e15;
        vm.prank(addrC);
        stakeC.setRewardRate(rewardRate);
        assertEq(stakeC.rewardPerBlock(), rewardRate);
    }

    function test_SetRewardRateUnauthorizedRevert() public {
        uint256 rewardRate = 1e15;
        vm.prank(user);
        vm.expectRevert();
        stakeC.setRewardRate(rewardRate);
    }

    // ---stake---
    function test_StakeSuccess() public {
        uint256 amount = 1 ether;
        uint256 prevTotal = stakeC.totalStaked();
        vm.deal(user, amount);
        vm.prank(user);
        stakeC.stake{value: amount}(amount);

        assertEq(stakeC.totalStaked(), prevTotal + amount);
        assertEq(flakeEth.balanceOf(user), amount);
        assertTrue(achievementNft.hasAchievement(user, 1));
        assertTrue(!achievementNft.hasAchievement(user, 2));
        assertEq(user.balance, 0);
    }

    function test_StakeWhaleAchievement() public {
        uint256 amount = 2 ether;
        vm.deal(user, amount);
        vm.prank(user);
        stakeC.stake{value: amount}(amount);
        assertTrue(achievementNft.hasAchievement(user, 2));
    }

    function test_StakeZeroAmountReverts() public {
        uint256 amount = 0;
        vm.prank(user);
        vm.expectRevert("Amount must be greater than zero");
        stakeC.stake{value: amount}(amount);
    }

    function test_StakeMsgValueMismatchReverts() public {
        vm.deal(user, 1 ether);
        vm.prank(user);
        vm.expectRevert("Amount must be equal to msg.value");
        stakeC.stake{value: 0.5 ether}(1 ether);
    }

    // ---unstake---
    function test_UnstakeSuccess() public {
        uint256 amount = 1 ether;
        _stakeAs(user, amount);
        (
            uint256 staked,
            uint256 pending,
            uint256 stakedBlockNum,
            uint256 stakedTimestamp,
            bool hasGenesis,
            bool hasWhale,
            bool hasDiamondHands
        ) = stakeC.getStakeInfo(user);

        vm.warp(stakedTimestamp + 8 days);
        vm.roll(stakedBlockNum + 1000);

        uint256 prevPending = stakeC.pendingRewards(user);
        uint256 prevTotal = stakeC.totalStaked();
        vm.prank(user);
        stakeC.unstake(amount);
        (
            staked,
            pending,
            stakedBlockNum,
            stakedTimestamp,
            hasGenesis,
            hasWhale,
            hasDiamondHands
        ) = stakeC.getStakeInfo(user);

        // checking if stakedAmount is now 0
        assertEq(staked, 0, "StakedAmount not zero");
        // check if pending is now 0
        assertEq(pending, 0, "Amount pending not reset");
        // check if stakedBlockNum is reset
        assertEq(stakedBlockNum, 0, "lastClaimBlock not reset");
        // check if stakedTimestamp has been reset
        assertEq(stakedTimestamp, 0, "stakedBlockTimestamp not resetted");
        // check if flakeTOKEN equal to pending rewards is minted
        assertEq(flake.balanceOf(user), prevPending, "Pending amount not minted");
        // check if LST (FlakeEth is burnt)
        assertEq(flakeEth.balanceOf(user), 0, "LST not burnt");
        // checking if diamond hands is minted to user
        assertTrue(hasDiamondHands);
        // checking if totalStaked has been deducted
        assertEq(prevTotal - amount, stakeC.totalStaked(), "Total Staked not deducted");
        // check if user is returned their eth
        assertEq(user.balance, amount, "User balance differs");
    }

    function test_UnstakeAmountZero() public {
        vm.prank(user);
        vm.expectRevert("Insufficient Balance");
        stakeC.unstake(0);
    }

    function test_UnstakeTransferFail() public {
        address noReceive = address(new RejectETH());
        uint256 amount = 1 ether;
        _stakeAs(noReceive, amount);
        vm.prank(noReceive);
        vm.etch(user, "");
        vm.expectRevert("Transfer Failed");
        stakeC.unstake(amount);
    }

    // ---claimRewards---
    function test_ClaimRewardsSuccess() public {
        uint256 amount = 1 ether;
        _stakeAs(user, amount);
        (
            uint256 staked,
            uint256 pending,
            uint256 stakedBlockNum,
            uint256 stakedTimestamp,
            bool hasGenesis,
            bool hasWhale,
            bool hasDiamondHands
        ) = stakeC.getStakeInfo(user);
        vm.roll(stakedBlockNum + 1000);
        vm.warp(stakedTimestamp + 10 days);
        uint256 prevStakedBlock = stakedBlockNum;
        uint256 prevPending = stakeC.pendingRewards(user);
        vm.prank(user);
        stakeC.claimRewards();
        assertEq(flake.balanceOf(user), prevPending, "Pending Rewards Not Minted");
        (
            staked,
            pending,
            stakedBlockNum,
            stakedTimestamp,
            hasGenesis,
            hasWhale,
            hasDiamondHands
        ) = stakeC.getStakeInfo(user);
        assertEq(stakedBlockNum, prevStakedBlock + 1000, "StakedBlock Differs");
    }
}

contract RejectETH {
    receive() external payable {
        revert();
    }
}
