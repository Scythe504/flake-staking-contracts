// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {AchievementNFT} from "src/AchievementNFT.sol";

contract AchievementNftTest is Test {
    AchievementNFT achievementNft;
    address minter = vm.addr(1);
    address user = vm.addr(2);

    function setUp() public {
        achievementNft = new AchievementNFT(minter);
    }

    function test_Mint_GrantsBadges() public {
        vm.startPrank(minter);
        achievementNft.mint(user, 1);
        achievementNft.mint(user, 2);
        achievementNft.mint(user, 3);
        vm.stopPrank();
        assertTrue(achievementNft.hasAchievement(user, 1));
        assertTrue(achievementNft.hasAchievement(user, 2));
        assertTrue(achievementNft.hasAchievement(user, 3));
    }

    function test_Mint_IncrementsTokenId() public {
        vm.startPrank(minter);
        achievementNft.mint(user, 1);
        achievementNft.mint(user, 2);
        vm.stopPrank();
        assertEq(achievementNft.ownerOf(0), user);
        assertEq(achievementNft.ownerOf(1), user);
    }

    function test_RevertIf_MintDuplicateBadge() public {
        vm.startPrank(minter);
        achievementNft.mint(user, 1);
        vm.expectRevert("Already earned");
        achievementNft.mint(user, 1);
        vm.stopPrank();
    }

    function test_RevertIf_MintUnauthorized() public {
        vm.prank(user);
        vm.expectRevert();
        achievementNft.mint(user, 1);
    }

    function test_RevertIf_MintInvalidBadge() public {
        vm.startPrank(minter);
        vm.expectRevert("Invalid Badge Id!");
        achievementNft.mint(user, 0);

        vm.expectRevert("Invalid Badge Id!");
        achievementNft.mint(user, 4);
        vm.stopPrank();
    }

    function test_RevertIf_TokenURINonExistentToken() public {
        vm.expectRevert();
        achievementNft.tokenURI(999);
    }

    function test_TokenURI_ReturnsDataForValidToken() public {
        vm.prank(minter);
        achievementNft.mint(user, 1);

        string memory uri = achievementNft.tokenURI(0);

        // just assert it starts with the expected prefix
        assertTrue(bytes(uri).length > 0, "URI should not be empty");
        assertEq(_substring(uri, 0, 29), "data:application/json;base64,");
    }

    function test_TokenURI_DifferentForBadges() public {
        vm.startPrank(minter);
        achievementNft.mint(user, 1);
        achievementNft.mint(user, 2);
        achievementNft.mint(user, 3);
        vm.stopPrank();

        string memory uri1 = achievementNft.tokenURI(0);
        string memory uri2 = achievementNft.tokenURI(1);
        string memory uri3 = achievementNft.tokenURI(2);

        assertTrue(keccak256(bytes(uri1)) != keccak256(bytes(uri2)), "URI 1 and 2 should differ");
        assertTrue(keccak256(bytes(uri2)) != keccak256(bytes(uri3)), "URI 2 and 3 should differ");
        assertTrue(keccak256(bytes(uri1)) != keccak256(bytes(uri3)), "URI 1 and 3 should differ");
    }

    // helper
    function _substring(
        string memory str,
        uint256 start,
        uint256 end
    ) internal pure returns (string memory) {
        bytes memory strBytes = bytes(str);
        bytes memory result = new bytes(end - start);
        for (uint256 i = start; i < end; i++) {
            result[i - start] = strBytes[i];
        }
        return string(result);
    }
}
