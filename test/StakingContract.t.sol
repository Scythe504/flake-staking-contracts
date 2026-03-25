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
    function test_SetRewardRate_Success() public {
        uint256 rewardRate = 1e15;
        vm.prank(addrC);
        stakeC.setRewardRate(rewardRate);
        assertEq(stakeC.rewardPerBlock(), rewardRate);
    }

    function test_RevertIf_SetRewardRateUnauthorized() public {
        uint256 rewardRate = 1e15;
        vm.prank(user);
        vm.expectRevert();
        stakeC.setRewardRate(rewardRate);
    }

    // ---stake---
    function test_Stake_Success() public {
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

    function test_Stake_WhaleAchievement() public {
        uint256 amount = 2 ether;
        vm.deal(user, amount);
        vm.prank(user);
        stakeC.stake{value: amount}(amount);
        assertTrue(achievementNft.hasAchievement(user, 2));
    }

    function test_RevertIf_StakeZeroAmount() public {
        uint256 amount = 0;
        vm.prank(user);
        vm.expectRevert("Amount must be greater than zero");
        stakeC.stake{value: amount}(amount);
    }

    function test_RevertIf_StakeMsgValueMismatch() public {
        vm.deal(user, 1_000_000_000_000_000_000); // 1 ether
        vm.prank(user);
        vm.expectRevert("Amount must be equal to msg.value");
        stakeC.stake{value: 0.5 ether}(1 ether);
    }

    // ---unstake---
    function test_Unstake_Success() public {
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

    function test_RevertIf_UnstakeAmountZero() public {
        vm.prank(user);
        vm.expectRevert("Insufficient Balance");
        stakeC.unstake(0);
    }

    function test_RevertIf_UnstakeTransferFail() public {
        address noReceive = address(new RejectETH());
        uint256 amount = 1 ether;
        _stakeAs(noReceive, amount);
        vm.prank(noReceive);
        vm.expectRevert("Transfer Failed");
        stakeC.unstake(amount);
    }

    // ---claimRewards---
    function test_ClaimRewards_Success() public {
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

    function test_Unstake_Partial() public {
        uint256 amount = 2 ether;
        _stakeAs(user, amount);
        
        uint256 unstakeAmount = 1 ether;
        vm.roll(block.number + 100);
        
        uint256 initialPending = stakeC.pendingRewards(user);
        
        vm.prank(user);
        stakeC.unstake(unstakeAmount);
        
        (uint256 staked, , uint256 lastClaimBlock, , , , ) = stakeC.getStakeInfo(user);
        
        assertEq(staked, amount - unstakeAmount, "Remaining staked mismatch");
        assertEq(flake.balanceOf(user), initialPending, "Rewards not claimed on partial unstake");
        assertEq(lastClaimBlock, block.number, "lastClaimBlock should update on partial unstake");
    }

    function test_Unstake_NoDiamondHands_BeforeSevenDays() public {
        uint256 amount = 1 ether;
        _stakeAs(user, amount);
        
        ( , , , uint256 stakedTimestamp, , , ) = stakeC.getStakeInfo(user);
        
        // Warp to 6 days
        vm.warp(stakedTimestamp + 6 days);
        
        vm.prank(user);
        stakeC.unstake(amount);
        
        ( , , , , , , bool hasDiamondHands) = stakeC.getStakeInfo(user);
        assertTrue(!hasDiamondHands, "Should not have Diamond Hands badge before 7 days");
    }

    function test_ClaimRewards_ZeroStaked() public {
        vm.prank(user);
        stakeC.claimRewards();
        assertEq(flake.balanceOf(user), 0);
    }

    function test_ClaimRewards_Twice() public {
        uint256 amount = 1 ether;
        _stakeAs(user, amount);
        
        vm.roll(block.number + 100);
        uint256 firstPending = stakeC.pendingRewards(user);
        
        vm.startPrank(user);
        stakeC.claimRewards();
        assertEq(flake.balanceOf(user), firstPending);
        
        stakeC.claimRewards();
        assertEq(flake.balanceOf(user), firstPending, "Balance should not increase on second claim in same block");
        vm.stopPrank();
    }

    function test_PendingRewards_Direct() public {
        uint256 amount = 1 ether;
        _stakeAs(user, amount);
        
        vm.roll(block.number + 50);
        uint256 pending = stakeC.pendingRewards(user);
        uint256 expected = (amount * 50 * stakeC.rewardPerBlock()) / 1e18;
        assertEq(pending, expected);
    }

    function test_Fuzz_PendingRewards(uint256 amount, uint256 blocks) public {
        // Limit amount to avoid overflow in pendingRewards calculation
        // amount * blocks * rewardPerBlock / 1e18
        // rewardPerBlock is 1e14
        // Max uint256 is ~1.15e77
        // Let's cap amount at 1e30 (1 trillion trillion tokens) and blocks at 1e10
        amount = 1e14 + (amount % (1e30 - 1e14 + 1));
        blocks = 1 + (blocks % (1e10));
        
        vm.deal(user, amount);
        vm.prank(user);
        stakeC.stake{value: amount}(amount);
        
        uint256 startBlock = block.number;
        vm.roll(startBlock + blocks);
        
        uint256 pending = stakeC.pendingRewards(user);
        uint256 expected = (amount * blocks * stakeC.rewardPerBlock()) / 1e18;
        assertEq(pending, expected);
    }

    function test_MultipleUsers_IndependentRewards() public {
        address alice = vm.addr(10);
        address bob = vm.addr(11);
        uint256 amountA = 1 ether;
        uint256 amountB = 2 ether;

        // Alice stakes at block 1
        vm.roll(1);
        _stakeAs(alice, amountA);

        // Wait 50 blocks
        vm.roll(51);

        // Bob stakes at block 51
        _stakeAs(bob, amountB);

        // Wait another 50 blocks (Total 100 blocks)
        vm.roll(101);

        uint256 alicePending = stakeC.pendingRewards(alice);
        uint256 bobPending = stakeC.pendingRewards(bob);

        // Alice: 100 blocks * 1 ETH * rate
        uint256 expectedAlice = (amountA * 100 * stakeC.rewardPerBlock()) / 1e18;
        // Bob: 50 blocks * 2 ETH * rate
        uint256 expectedBob = (amountB * 50 * stakeC.rewardPerBlock()) / 1e18;

        assertEq(alicePending, expectedAlice, "Alice reward mismatch");
        assertEq(bobPending, expectedBob, "Bob reward mismatch");
    }

    function test_MultipleStakes_RewardsAreFair() public {
        // This test now verifies that staking twice
        // correctly checkpoints rewards and updates the stake fairly.
        uint256 amount1 = 1 ether;
        uint256 amount2 = 1 ether;

        vm.roll(1);
        _stakeAs(user, amount1);

        vm.roll(51);
        // User stakes again. Rewards from the first 50 blocks (1 ETH) are minted here.
        uint256 firstPending = (amount1 * 50 * stakeC.rewardPerBlock()) / 1e18;
        _stakeAs(user, amount2);

        assertEq(flake.balanceOf(user), firstPending, "Rewards should be minted on second stake");

        vm.roll(101);
        uint256 secondPending = stakeC.pendingRewards(user);

        // Fair calculation for second window: (2 ETH * 50 blocks * rate)
        uint256 expectedSecond = (2 ether * 50 * stakeC.rewardPerBlock()) / 1e18;

        assertEq(secondPending, expectedSecond, "Second window rewards mismatch");
        assertEq(flake.balanceOf(user), firstPending, "Current balance should match first minted rewards");
    }

    function test_RevertIf_UnstakeExceedsBalance() public {
        uint256 amount = 1 ether;
        _stakeAs(user, amount);
        
        vm.prank(user);
        vm.expectRevert("Insufficient Balance");
        stakeC.unstake(amount + 1);
    }

    function test_StakeTimestamp_Persistence() public {
        uint256 amount = 1 ether;
        _stakeAs(user, amount);
        
        ( , , , uint256 firstTimestamp, , , ) = stakeC.getStakeInfo(user);
        
        vm.warp(block.timestamp + 3 days);
        
        // Stake again
        _stakeAs(user, amount);
        
        ( , , , uint256 secondTimestamp, , , ) = stakeC.getStakeInfo(user);
        
        assertEq(firstTimestamp, secondTimestamp, "Timestamp should not reset on second stake");
        
        // Warp another 5 days (Total 8 days since first stake)
        vm.warp(block.timestamp + 5 days);
        
        vm.prank(user);
        stakeC.unstake(amount * 2);
        
        ( , , , , , , bool hasDiamondHands) = stakeC.getStakeInfo(user);
        assertTrue(hasDiamondHands, "Should earn Diamond Hands based on original timestamp");
    }

    function test_StakeTimestamp_ResetAfterFullUnstake() public {
        uint256 amount = 1 ether;
        _stakeAs(user, amount);
        
        vm.prank(user);
        stakeC.unstake(amount);
        
        ( , , , uint256 timestampAfterFullUnstake, , , ) = stakeC.getStakeInfo(user);
        assertEq(timestampAfterFullUnstake, 0, "Timestamp should reset to 0 after full unstake");
        
        vm.warp(block.timestamp + 10 days);
        
        // Stake again - clock should start fresh
        _stakeAs(user, amount);
        ( , , , uint256 newTimestamp, , , ) = stakeC.getStakeInfo(user);
        assertEq(newTimestamp, block.timestamp, "New clock should start at current timestamp");
    }

    function test_TotalStaked_Consistency() public {
        address alice = vm.addr(20);
        address bob = vm.addr(21);
        
        _stakeAs(alice, 10 ether);
        _stakeAs(bob, 5 ether);
        assertEq(stakeC.totalStaked(), 15 ether);
        
        vm.prank(alice);
        stakeC.unstake(4 ether);
        assertEq(stakeC.totalStaked(), 11 ether);
        
        vm.prank(bob);
        stakeC.unstake(5 ether);
        assertEq(stakeC.totalStaked(), 6 ether);
    }
}

contract RejectETH {
    receive() external payable {
        revert();
    }
}
