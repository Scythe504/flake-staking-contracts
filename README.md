# Flake Staking Protocol

A high-performance, gas-optimized, and upgradeable liquid staking protocol with automated rewards and milestone-based achievements.

## 🚀 Deployment Addresses

### Ethereum Sepolia Testnet
| Contract | Address |
| :--- | :--- |
| **Main Proxy (User Interaction)** | `0xf774f60C1418576f2FF1E92dF6a01910b336702d` |
| **FlakeETH (LST Token)** | `0x73cCeaC8d335bfeC023ef2B51A89D783af80c368` |
| **FlakeToken (Reward Token)** | `0x6c6e775F1FF9C26B063beD050D45BF7ac424e533` |
| **AchievementNFT (Badges)** | `0xF037Fe925606BEf55E3a2bECad71ab0E5B3F50f8` |
| **StakingContract (Implementation)** | `0x069141E8B039FF1bf85baBA431de7cbec246d8Bc` |

### Base Sepolia Testnet
| Contract | Address |
| :--- | :--- |
| **Main Proxy (User Interaction)** | `0xf774f60C1418576f2FF1E92dF6a01910b336702d` |
| **FlakeETH (LST Token)** | `0x73cCeaC8d335bfeC023ef2B51A89D783af80c368` |
| **FlakeToken (Reward Token)** | `0x6c6e775F1FF9C26B063beD050D45BF7ac424e533` |
| **AchievementNFT (Badges)** | `0xF037Fe925606BEf55E3a2bECad71ab0E5B3F50f8` |
| **StakingContract (Implementation)** | `0x069141E8B039FF1bf85baBA431de7cbec246d8Bc` |

> **Note**: Both deployments used the same addresses due to identical nonces and salt-less deployment patterns. Ensure you are connected to the correct network when interacting.

## 🛠 Frontend Integration Snippet (Next.js)

```typescript
export const PROTOCOL_ADDRESSES = {
  stakingProxy: "0xf774f60C1418576f2FF1E92dF6a01910b336702d",
  flakeETH: "0x73cCeaC8d335bfeC023ef2B51A89D783af80c368",
  flakeToken: "0x6c6e775F1FF9C26B063beD050D45BF7ac424e533",
  achievementNFT: "0xF037Fe925606BEf55E3a2bECad71ab0E5B3F50f8"
} as const;
```

## 🏗 Features
- **UUPS Upgradeability**: Full logic portability without losing state.
- **Gas Optimized**: Packed `UserInfo` structs and localized achievement caching.
- **Fair Rewards**: Checkpoint-based reward calculation ensures mathematical precision.
- **Dynamic Achievements**: IPFS-linked high-fidelity badges for Genesis, Whale, and Diamond Hand stakers.

## 📜 Development
- **Tests**: 49 comprehensive test cases (Foundry).
- **Security**: Strict AccessControl and Transient Reentrancy protection.