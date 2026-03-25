// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {
    ReentrancyGuardTransient
} from "@openzeppelin/contracts/utils/ReentrancyGuardTransient.sol";
import {FlakeETH} from "./FlakeETH.sol";
import {FlakeToken} from "./FlakeToken.sol";
import {AchievementNFT} from "./AchievementNFT.sol";

contract StakingContract is
    AccessControlUpgradeable,
    OwnableUpgradeable,
    ReentrancyGuardTransient,
    UUPSUpgradeable
{
    bytes32 public constant OWNER = keccak256("OWNER");
    mapping(address => uint256) stakedAmount;
    mapping(address => uint256) stakeTimestamp;
    mapping(address => uint256) lastClaimBlock;
    uint256 public rewardPerBlock;
    uint256 public totalStaked;
    FlakeETH public flakeETH;
    FlakeToken public flake;
    AchievementNFT public achievementNFT;

    function initialize(
        address _flakeETH,
        address _flake,
        address _achievementNFT
    ) public initializer {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        flakeETH = FlakeETH(_flakeETH);
        flake = FlakeToken(_flake);
        achievementNFT = AchievementNFT(_achievementNFT);
        rewardPerBlock = 1e14;
    }

    function setRewardPerBlock(uint256 amount) public onlyRole(OWNER) {
        rewardPerBlock = amount;
    }

    function stake(uint256 amount) external payable nonReentrant {
        require(amount > 0, "Amount must be greater than zero");
        require(msg.value == amount, "Amount must be equal to msg.value");
        stakedAmount[msg.sender] += amount;

        if (lastClaimBlock[msg.sender] == 0) {
            lastClaimBlock[msg.sender] = block.number;
        }

        if (stakeTimestamp[msg.sender] == 0) {
            stakeTimestamp[msg.sender] = block.timestamp;
        }

        flakeETH.mint(msg.sender, amount);

        if (!achievementNFT.hasAchievement(msg.sender, 1)) {
            achievementNFT.mint(msg.sender, 1);
        }

        if (amount > 1 ether) achievementNFT.mint(msg.sender, 2);

        totalStaked += amount;
    }

    function unstake(uint256 amount) external nonReentrant {
        require(
            amount > 0 && amount <= stakedAmount[msg.sender],
            "Insufficient Balance"
        );
        flake.mint(msg.sender, pendingRewards(msg.sender));
        flakeETH.burn(msg.sender, amount);
        stakedAmount[msg.sender] -= amount;
        if (block.timestamp - stakeTimestamp[msg.sender] > 7 days)
            achievementNFT.mint(msg.sender, 3);

        if (stakedAmount[msg.sender] == 0) {
            stakeTimestamp[msg.sender] = 0;
            lastClaimBlock[msg.sender] = 0;
        } else {
            lastClaimBlock[msg.sender] = block.number;
        }

        totalStaked -= amount;
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Transfer Failed");
    }

    function claimRewards() external nonReentrant {
        uint256 rewards = pendingRewards(msg.sender);
        lastClaimBlock[msg.sender] = block.number;
        flake.mint(msg.sender, rewards);
    }

    function pendingRewards(address user) public view returns (uint256) {
        uint256 pending = (stakedAmount[user] *
            (block.number - lastClaimBlock[user]) *
            rewardPerBlock) / 1e18;
        return pending;
    }

    function getStakeInfo(
        address user
    )
        external
        view
        returns (
            uint256 staked,
            uint256 pending,
            uint256 stakedSince,
            bool hasGenesis,
            bool hasWhale,
            bool hasDiamondHands
        )
    {
        uint256 _staked = stakedAmount[user];
        uint256 _pending = pendingRewards(user);
        uint256 _stakedSince = lastClaimBlock[user];
        bool _hasGenesis = achievementNFT.hasAchievement(user, 1);
        bool _hasWhale = achievementNFT.hasAchievement(user, 2);
        bool _hasDiamondHands = achievementNFT.hasAchievement(user, 3);

        return (
            _staked,
            _pending,
            _stakedSince,
            _hasGenesis,
            _hasWhale,
            _hasDiamondHands
        );
    }

    function setRewardRate(uint256 _rate) external onlyRole(OWNER) {
        rewardPerBlock = _rate;
    }

    function _authorizeUpgrade(
        address newImpl
    ) internal override onlyRole(OWNER) {}
}
