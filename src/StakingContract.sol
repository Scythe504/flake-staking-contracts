// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {
    ReentrancyGuardTransient
} from "@openzeppelin/contracts/utils/ReentrancyGuardTransient.sol";
import {FlakeETH} from "./FlakeETH.sol";
import {FlakeToken} from "./FlakeToken.sol";
import {AchievementNFT} from "./AchievementNFT.sol";

contract StakingContract is
    AccessControlUpgradeable,
    ReentrancyGuardTransient,
    UUPSUpgradeable
{
    bytes32 public constant OWNER = keccak256("OWNER");

    struct UserInfo {
        uint256 amount;
        uint64 lastClaimBlock;
        uint64 stakeTimestamp;
        bool hasGenesis;
        bool hasWhale;
        bool hasDiamondHands;
    }

    mapping(address => UserInfo) public userInfo;

    uint256 public rewardPerBlock;
    uint256 public totalStaked;
    FlakeETH public flakeEth;
    FlakeToken public flake;
    AchievementNFT public achievementNft;

    function initialize(
        address _flakeEth,
        address _flake,
        address _achievementNft
    ) public initializer {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(OWNER, msg.sender);
        flakeEth = FlakeETH(_flakeEth);
        flake = FlakeToken(_flake);
        achievementNft = AchievementNFT(_achievementNft);
        rewardPerBlock = 1e14;
    }

    function stake(uint256 amount) external payable nonReentrant {
        require(amount > 0, "Amount must be greater than zero");
        require(msg.value == amount, "Amount must be equal to msg.value");

        UserInfo storage user = userInfo[msg.sender];

        if (user.amount > 0) {
            uint256 rewards = _calculatePendingRewards(user);
            if (rewards > 0) flake.mint(msg.sender, rewards);
        }

        user.lastClaimBlock = uint64(block.number);

        if (user.stakeTimestamp == 0) {
            user.stakeTimestamp = uint64(block.timestamp);
        }

        user.amount += amount;
        flakeEth.mint(msg.sender, amount);

        if (!user.hasGenesis) {
            user.hasGenesis = true;
            achievementNft.mint(msg.sender, 1);
        }

        if (!user.hasWhale && user.amount > 1 ether) {
            user.hasWhale = true;
            achievementNft.mint(msg.sender, 2);
        }

        totalStaked += amount;
    }

    function unstake(uint256 amount) external nonReentrant {
        UserInfo storage user = userInfo[msg.sender];
        require(amount > 0 && amount <= user.amount, "Insufficient Balance");

        uint256 rewards = _calculatePendingRewards(user);
        if (rewards > 0) flake.mint(msg.sender, rewards);

        flakeEth.burn(msg.sender, amount);
        user.amount -= amount;

        if (
            !user.hasDiamondHands &&
            block.timestamp - user.stakeTimestamp > 7 days
        ) {
            user.hasDiamondHands = true;
            achievementNft.mint(msg.sender, 3);
        }

        if (user.amount == 0) {
            user.stakeTimestamp = 0;
            user.lastClaimBlock = 0;
        } else {
            user.lastClaimBlock = uint64(block.number);
        }

        totalStaked -= amount;
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Transfer Failed");
    }

    function claimRewards() external nonReentrant {
        UserInfo storage user = userInfo[msg.sender];
        uint256 rewards = _calculatePendingRewards(user);
        user.lastClaimBlock = uint64(block.number);
        if (rewards > 0) flake.mint(msg.sender, rewards);
    }

    function pendingRewards(address userAddr) public view returns (uint256) {
        return _calculatePendingRewards(userInfo[userAddr]);
    }

    function _calculatePendingRewards(
        UserInfo memory user
    ) internal view returns (uint256) {
        if (user.amount == 0 || user.lastClaimBlock == 0) return 0;
        return
            (user.amount * (block.number - user.lastClaimBlock) * rewardPerBlock) /
            1e18;
    }

    function getStakeInfo(
        address userAddr
    )
        external
        view
        returns (
            uint256 staked,
            uint256 pending,
            uint256 stakedBlockNum,
            uint256 stakedTimestamp,
            bool hasGenesis,
            bool hasWhale,
            bool hasDiamondHands
        )
    {
        UserInfo storage user = userInfo[userAddr];
        return (
            user.amount,
            _calculatePendingRewards(user),
            user.lastClaimBlock,
            user.stakeTimestamp,
            user.hasGenesis,
            user.hasWhale,
            user.hasDiamondHands
        );
    }

    function setRewardRate(uint256 _rate) external onlyRole(OWNER) {
        rewardPerBlock = _rate;
    }

    function _authorizeUpgrade(
        address newImpl
    ) internal override onlyRole(OWNER) {}
}
