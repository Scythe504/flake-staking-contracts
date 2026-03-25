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
    mapping(address => uint256) stakedAmount;
    mapping(address => uint256) stakeTimestamp;
    mapping(address => uint256) lastClaimBlock;
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
        _grantRole(OWNER, msg.sender);
        flakeEth = FlakeETH(_flakeEth);
        flake = FlakeToken(_flake);
        achievementNft = AchievementNFT(_achievementNft);
        rewardPerBlock = 1e14;
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

        flakeEth.mint(msg.sender, amount);

        if (!achievementNft.hasAchievement(msg.sender, 1)) {
            achievementNft.mint(msg.sender, 1);
        }

        if (!achievementNft.hasAchievement(msg.sender, 2) && amount > 1 ether)
            achievementNft.mint(msg.sender, 2);

        totalStaked += amount;
    }

    function unstake(uint256 amount) external nonReentrant {
        require(
            amount > 0 && amount <= stakedAmount[msg.sender],
            "Insufficient Balance"
        );
        flake.mint(msg.sender, pendingRewards(msg.sender));
        flakeEth.burn(msg.sender, amount);
        stakedAmount[msg.sender] -= amount;
        if (
            !achievementNft.hasAchievement(msg.sender, 3) &&
            block.timestamp - stakeTimestamp[msg.sender] > 7 days
        ) achievementNft.mint(msg.sender, 3);

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
            uint256 stakedBlockNum,
            uint256 stakedTimestamp,
            bool hasGenesis,
            bool hasWhale,
            bool hasDiamondHands
        )
    {
        uint256 _staked = stakedAmount[user];
        uint256 _pending = pendingRewards(user);
        uint256 _stakedBlockNum = lastClaimBlock[user];
        uint256 _stakedTimestamp = stakeTimestamp[user];
        bool _hasGenesis = achievementNft.hasAchievement(user, 1);
        bool _hasWhale = achievementNft.hasAchievement(user, 2);
        bool _hasDiamondHands = achievementNft.hasAchievement(user, 3);

        return (
            _staked,
            _pending,
            _stakedBlockNum,
            _stakedTimestamp,
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
