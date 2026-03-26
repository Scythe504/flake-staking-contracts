# Flake Staking Protocol

Stake ETH, receive sbFlakeETH as a 1:1 soulbound receipt, earn $FLAKE rewards, and unlock milestone-based achievement badges.

**Web Client**: [flake-stake-web](https://github.com/scythe504/flake-stake-web)

---

## How It Works

```
Stake ETH
    │
    ▼
Receive sbFlakeETH  (Soulbound ERC-20, 1:1)
    │
    ▼
Earn $FLAKE rewards  (ERC-20, transferable)
    │
    ▼
Unlock Achievement NFTs  (Soulbound ERC-721)
```

| Token | Standard | Transferable | Description |
|:------|:---------|:-------------|:------------|
| **sbFlakeETH** | ERC-20 (Soulbound) | No | 1:1 receipt for staked ETH |
| **$FLAKE** | ERC-20 | Yes | Reward token earned over time |
| **Achievement NFTs** | ERC-721 (Soulbound) | No | Genesis / Whale / Diamond Hand badges |

---

## Achievements

Soulbound ERC-721 badges with IPFS-linked artwork, awarded at staking milestones.

| Name | Description |
|:-----|:------------|
| **Genesis** | Early staker milestone |
| **Whale** | Large stake milestone |
| **Diamond Hand** | Long-term staking milestone |

---

## Deployment Addresses

### Ethereum Sepolia

| Contract | Address |
|:---------|:--------|
| **Main Proxy** *(interact here)* | `0xf774f60C1418576f2FF1E92dF6a01910b336702d` |
| **sbFlakeETH** | `0x1C13Cd67dBEb01C24ded06322131cc5a83d9CA5E` |
| **$FLAKE Token** | `0x6c6e775F1FF9C26B063beD050D45BF7ac424e533` |
| **Achievement NFT** | `0x0aCC39977CD78129a77a209bf9B39C5Ee1C4a68F` |
| **Implementation** | `0x41a309131A7903c967DF70A94DbA048ee842C2DA` |

### Base

| Contract | Address |
|:---------|:--------|
| **Main Proxy** *(interact here)* | `0xf774f60C1418576f2FF1E92dF6a01910b336702d` |
| **sbFlakeETH** | `0xA917Aa70d9538c4fC4B6653037f51C0EBCe56652` |
| **$FLAKE Token** | `0x6c6e775F1FF9C26B063beD050D45BF7ac424e533` |
| **Achievement NFT** | `0x41a309131A7903c967DF70A94DbA048ee842C2DA` |
| **Implementation** | `0xdcd4Bee9556A5D545FC6bB603264515b2385Ba2a` |

> Always interact via the Main Proxy, not the implementation contract directly.

---

## Architecture

| Feature | Detail |
|:--------|:-------|
| **UUPS Upgradeability** | Full logic portability without losing state |
| **Gas Optimized** | Packed `UserInfo` structs and localized achievement caching |
| **Fair Rewards** | Checkpoint-based calculation ensures mathematical precision |
| **Soulbound Tokens** | sbFlakeETH and Achievement NFTs are non-transferable |
| **Reentrancy Protection** | Transient storage-based reentrancy guard |
| **Access Control** | Role-based permissions via OpenZeppelin |

---

## Development

```bash
# Run tests
forge test

# Deploy
forge script script/Deploy.s.sol --rpc-url $RPC_URL --broadcast
```

- 49 comprehensive test cases (Foundry)
- OpenZeppelin AccessControl + Transient Reentrancy Guard

---

## License

MIT
