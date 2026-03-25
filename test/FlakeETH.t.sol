// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {FlakeETH} from "src/FlakeETH.sol";

contract FlakeEthTest is Test {
    FlakeETH flakeEth;
    address minter = vm.addr(1);
    address user = vm.addr(2);

    function setUp() public {
        flakeEth = new FlakeETH(minter);
    }

    function testMintIncreaseBalance() public { 
        uint256 amount = 1 ether;
        vm.prank(minter);
        flakeEth.mint(user, amount);
        assertEq(flakeEth.balanceOf(user), 1 ether);
    }

    function testMintUnauthorizedReverts() public {
        uint256 amount = 1 ether;
        vm.prank(user);
        vm.expectRevert();
        flakeEth.mint(user, amount);
    }

    function testBurnDecreasesBalance() public {
        uint256 amount = 2 ether;
        vm.startPrank(minter);
        flakeEth.mint(user, amount);
        flakeEth.burn(user, amount / 2);
        assertEq(flakeEth.balanceOf(user), 1 ether);
    }

    function testBurnUnauthorizedReverts() public {
        uint256 amount = 1 ether;
        vm.prank(minter);
        flakeEth.mint(user, amount);

        vm.prank(user);
        vm.expectRevert();
        flakeEth.burn(user, amount);
    }

    function testBurnMoreThanBalance() public {
        uint256 amount = 1 ether;
        vm.startPrank(minter);
        flakeEth.mint(user, amount);
        vm.expectRevert();
        flakeEth.burn(user, amount + 1);
        vm.stopPrank();
    }
}
