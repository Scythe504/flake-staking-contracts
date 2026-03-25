// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {StakingContract} from "../src/StakingContract.sol";
import {FlakeETH} from "../src/FlakeETH.sol";
import {FlakeToken} from "../src/FlakeToken.sol";
import {AchievementNFT} from "../src/AchievementNFT.sol";

contract AccessControlTest is Test {
    StakingContract stakeC;
    FlakeETH flakeEth;
    FlakeToken flake;
    AchievementNFT achievementNft;

    address owner = vm.addr(1);
    address alice = vm.addr(2);
    address bob = vm.addr(3);

    bytes32 public OWNER_ROLE;

    function setUp() public {
        vm.startPrank(owner);
        stakeC = new StakingContract();
        flakeEth = new FlakeETH(address(stakeC));
        flake = new FlakeToken(address(stakeC));
        achievementNft = new AchievementNFT(address(stakeC));

        stakeC.initialize(
            address(flakeEth),
            address(flake),
            address(achievementNft)
        );
        OWNER_ROLE = stakeC.OWNER();
        vm.stopPrank();
    }

    // --- OWNER ROLE ---

    function test_RevertIf_NonOwnerSetsRewardRate() public {
        uint256 newRate = 2e14;
        vm.prank(alice);
        vm.expectRevert();
        stakeC.setRewardRate(newRate);
    }

    function test_OwnerCanSetRewardRate() public {
        uint256 newRate = 2e14;
        vm.prank(owner);
        stakeC.setRewardRate(newRate);
        assertEq(stakeC.rewardPerBlock(), newRate);
    }

    function test_OwnerCanGrantRole() public {
        vm.prank(owner);
        stakeC.grantRole(OWNER_ROLE, alice);
        assertTrue(stakeC.hasRole(OWNER_ROLE, alice));
    }

    function test_OwnerCanRevokeOwnRole() public {
        vm.startPrank(owner);
        stakeC.revokeRole(OWNER_ROLE, owner);
        assertTrue(!stakeC.hasRole(OWNER_ROLE, owner));
        vm.stopPrank();
    }

    function test_RevertIf_NonAdminGrantsRole() public {
        vm.prank(alice);
        vm.expectRevert();
        stakeC.grantRole(OWNER_ROLE, bob);
    }

    // --- MINTER_ROLE ---

    function test_RevertIf_DirectMintingToTokens() public {
        vm.prank(alice);
        vm.expectRevert();
        flake.mint(alice, 1000);

        vm.prank(alice);
        vm.expectRevert();
        flakeEth.mint(alice, 1000);

        vm.prank(alice);
        vm.expectRevert();
        achievementNft.mint(alice, 1);
    }
}
