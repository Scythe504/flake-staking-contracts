// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {FlakeToken} from "src/FlakeToken.sol";

contract FlakeTokenTest is Test {
    FlakeToken flakeToken;
    address minter = vm.addr(1);
    address user = vm.addr(2);

    function setUp() public {
        flakeToken = new FlakeToken(minter);
    }

    function test_Mint_IncreasesBalance() public { 
        uint256 amount = 1 ether;
        vm.prank(minter);
        flakeToken.mint(user, amount);
        assertEq(flakeToken.balanceOf(user), 1 ether);
    }

    function test_RevertIf_MintUnauthorized() public {
        uint256 amount = 1 ether;
        vm.prank(user);
        vm.expectRevert();
        flakeToken.mint(user, amount);
    }
}
