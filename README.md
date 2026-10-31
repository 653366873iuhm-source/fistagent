# FISTAGENT

Independent fair-mint token on BNB Smart Chain for Binance Agentic Wallets holding a `.ai` Agent ID.
**Not affiliated with Binance. No promise of profit. Not audited.**

## Live (v2, BSC mainnet, minting open since 2026-10-31 14:34 CST)

| | Address |
|---|---|
| FistagentMint (v2) | `0x4738427479ff49D0f151e9069ceCfaadaEd35B30` |
| FistagentToken | `0x8E4e86ACfafcB2242B71f75e58fB627F1deaC2c1` |
| PancakeSwap FISTAGENT/USDT pair | `0x3A1C63c12297BECD3Ed3E0e36E5990d4251eC27c` |
| Treasury (taxes, post-pool mint payments) | `0x07Ed634a873D3aFCf7079616262D897C31b19353` |

Deploy tx `0x3bea79c84ca26250d6c58ddb605c31827bece03552c06e36aa23ed4c6cd5c89a`, block 130809409. Source verified on BscScan.
An earlier (v1) FISTAGENT mint contract was replaced by v2; only the addresses above are current.

## v2 rules

- 100,000,000 shares, nothing burned or reserved (`totalMinted` starts at 0).
- Shares #1–#2,000: **free**, one per `.ai` Agent ID (`claimFree()`), 50,000,000 FISTAGENT each. Does not use the paid quota and is not an invite trigger.
- Shares #2,001–#10,000: 1 USDT each, **100% of each payment parked in the mint contract** for the pool (paid mints revert `FreePhase` before share 2,001).
- The tx reaching share 10,000 opens the PancakeSwap pool automatically with everything parked (8,000 USDT + 400B FISTAGENT), LP burned to dead.
- After the pool opens: 100% of each mint payment goes to the treasury; price table unchanged (5,131 tiers, up to 79.74 USDT).
- Paid quota: 10 per Agent ID + invites + social tasks. Taxes: buy 1%, sell 1% burn + 1% treasury (BNB).
- 30-day valve: if share 10,000 is not reached by `mintDeadline()` (2026-11-30 14:34:33 CST), the treasury can withdraw the parked USDT (parked tokens go to dead); minting continues.
- The deployer wallet can only pause/unpause; all other admin rights sit with the treasury.

## Layout

- `src/` — `FistagentMint.sol` (v2 mint) and `FistagentToken.sol` (BEP-20 with transfer rules and taxes).
- `test/FistagentV2.t.sol` — BSC mainnet fork tests. `test/server/` — API tests (`node test/server/api.test.mjs`).
- `script/` — mainnet wiring (`BscConfig.sol`) and `DeployV2.s.sol`.
- `site/` — static website https://fistagent.onrender.com/ (`llms.txt`, `agent.md`, `skill.md`, whitepaper, A2A card).
- `server/` — Agentic Wallet QR-login proxy + social-task signer + public read API (Render web service `fistagent-api`). Env `ALLOW_TO` = mint contract.
- `skills/fistagent-mint/SKILL.md` — agent skill.

## Test

```
export BSC_RPC_URL=https://bsc-rpc.publicnode.com   # must serve state at FORK_BLOCK
export FORK_BLOCK=$(( $(cast block-number --rpc-url $BSC_RPC_URL) - 20 ))
forge test -vv
node test/server/api.test.mjs
```
Dependencies: forge-std, OpenZeppelin Contracts 5.6.1 (vendored under `lib/`).
