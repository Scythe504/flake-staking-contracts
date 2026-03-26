// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {Base64} from "@openzeppelin/contracts/utils/Base64.sol";

contract AchievementNFT is ERC721, AccessControl {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    event AchievementEarned(
        address indexed user,
        uint256 indexed badgeId,
        uint256 indexed tokenId
    );

    mapping(address => mapping(uint256 => bool)) public hasAchievement;
    mapping(uint256 => string) public badgeCID; // badgeId => IPFS CID
    mapping(uint256 => uint256) private _tokenBadgeType;
    uint256 private _nextTokenId;

    constructor(address proxyAddress) ERC721("Flake Achievements", "FACH") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, proxyAddress);
    }

    function setBadgeCID(
        uint256 badgeId,
        string calldata cid
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(badgeId >= 1 && badgeId <= 3, "Invalid Badge Id");
        badgeCID[badgeId] = cid;
    }

    function mint(address to, uint256 badgeId) external onlyRole(MINTER_ROLE) {
        require(badgeId >= 1 && badgeId <= 3, "Invalid Badge Id!");
        require(!hasAchievement[to][badgeId], "Already earned");
        hasAchievement[to][badgeId] = true;

        uint256 tokenId = _nextTokenId++;
        _tokenBadgeType[tokenId] = badgeId;
        _mint(to, tokenId);
        emit AchievementEarned(to, badgeId, tokenId);
    }

    function tokenURI(
        uint256 tokenId
    ) public view override returns (string memory) {
        _requireOwned(tokenId);

        uint256 badgeId = _tokenBadgeType[tokenId];
        string memory name;

        if (badgeId == 1) {
            name = "Genesis Staker";
        } else if (badgeId == 2) {
            name = "Whale";
        } else {
            name = "Diamond Hands";
        }

        // Build JSON metadata pointing to Pinata
        string memory json = string(
            abi.encodePacked(
                '{"name":"',
                name,
                '",',
                '"description":"Flake Staking Achievement",',
                '"image":"ipfs://',
                badgeCID[badgeId],
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

    function _update(
        address to,
        uint256 tokenId,
        address auth
    ) internal override returns (address) {
        address from = _ownerOf(tokenId);
        if (from != address(0) && to != address(0)) {
            revert("Achievements are Soulbound and non-transferable");
        }

        return super._update(to, tokenId, auth);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC721, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
