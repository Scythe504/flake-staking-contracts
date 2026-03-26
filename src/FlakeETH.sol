// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

contract FlakeETH is ERC20, AccessControl {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    constructor(address proxyAddress) ERC20("Flake sbETH", "flakeSBETH") {
        _grantRole(MINTER_ROLE, proxyAddress);
    }

    function mint(address to, uint256 amount) external onlyRole(MINTER_ROLE) {
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) external onlyRole(MINTER_ROLE) {
        _burn(from, amount);
    }

    function _update(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(
            from == address(0) || to == address(0),
            "FlakeETH is non-transferable"
        );
        super._update(from, to, amount);
    }
}
