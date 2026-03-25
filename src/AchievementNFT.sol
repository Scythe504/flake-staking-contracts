// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {Base64} from "@openzeppelin/contracts/utils/Base64.sol";

contract AchievementNFT is ERC721, AccessControl {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    mapping(address => mapping(uint256 => bool)) public hasAchievement;
    mapping(uint256 => uint256) private _tokenBadgeType;
    uint256 private _nextTokenId;

    constructor() ERC721("Flake Achievements", "FACH") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function mint(address to, uint256 badgeId) external onlyRole(MINTER_ROLE) {
        require(badgeId >= 1 && badgeId <= 3, "Invalid Badge!");
        require(!hasAchievement[to][badgeId], "Already earned");
        hasAchievement[to][badgeId] = true;

        uint256 tokenId = _nextTokenId++;
        _tokenBadgeType[tokenId] = badgeId;
        _mint(to, tokenId);
    }

    function tokenURI(
        uint256 tokenId
    ) public view override returns (string memory) {
        _requireOwned(tokenId);

        uint256 badgeId = _tokenBadgeType[tokenId];

        string memory name;
        string memory color;

        if (badgeId == 1) {
            name = "Genesis Staker";
            color = "#ff0000";
        } else if (badgeId == 2) {
            name = "Whale";
            color = "#0099ff";
        } else {
            name = "Diamond Hands";
            color = "#9000ff";
        }

        // build SVG
        string memory svg = string(
            abi.encodePacked(
                "<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 300 300'>",
                "<rect width='300' height='300' fill='",
                color,
                "'/>",
                "<text x='150' y='150' text-anchor='middle' fill='white' font-size='20'>",
                name,
                "</text>",
                "</svg>"
            )
        );

        // build JSON metadata
        string memory json = string(
            abi.encodePacked(
                '{"name":"',
                name,
                '",',
                '"description":"Flake Staking Achievement",',
                '"image":"data:image/svg+xml;base64,',
                Base64.encode(bytes(svg)),
                '"}'
            )
        );

        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(bytes(json))
                )
            );
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC721, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
