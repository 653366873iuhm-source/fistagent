# FISTAGENT — deployment plan (NOT DEPLOYED, nothing signed or broadcast)

Plan file: `deploy/bsc-mainnet-plan.json` (UNSIGNED; regenerate with `forge script script/BuildPlan.s.sol`, no RPC, no broadcast).
Both transactions are sent from the treasury Agentic Wallet. **The treasury/admin address must be confirmed by the user before tx 1**
(it is baked into the init code; changing it changes every address below).

| Item | Value |
|---|---|
| Network | BNB Smart Chain mainnet (chainId 56) |
| From / treasury / admin (immutable) | 0x49E6fb3812fdfD67eDfE17259f03CcbE59f39BCE (`allin168.ai`, confirmed by user 2026-10-30 21:50 CST) |
| Social-task signer (immutable) | 0x66ECa9C28e4e4807e37C078b917e527DC85aC199 (BNAGENT's dedicated signer, reused — see below) |
| CREATE2 deployer proxy | 0x4e59b44847b379578588920cA78FbF26c0B4956C |
| Salt | keccak256("FISTAGENT.mint.v1") = 0x0378f38f5ecaf6740316bdaac9858b588a1aca829923b8a0c57cae8af5415cc6 |
| initCodeHash | 0x2ca494a8b160fb19f23e9227b56012ee10c01fbf9462ae8fc0e46877f7d1549e |
| **FistagentMint** (planned) | **0xdDD8af1D1C9513D6eB5F4C017516360B26955c26** |
| **FistagentToken** (CREATE from mint, nonce 1) | **0x7acDcE948Dc6F9185D96b8D1af80284C9a3c71c3** |
| **PancakeSwap FISTAGENT/USDT pair** (created empty by the token constructor) | **0xf375Def1f8f60Bf52A2a8D4309498B1FCE45C01B** |
| Init code / runtime size | 27,268 bytes (limit 49,152) / mint runtime 18,449 bytes (limit 24,576) |
| Gas, tx 1 | `eth_estimateGas` on BSC mainnet 2026-10-30 ~18:20 CST from the treasury: **8,710,108**; used on a local anvil fork: 8,571,713. At 0.05 gwei ≈ 0.00044 BNB |

All three addresses had no code on BSC mainnet at 2026-10-30 ~18:20 CST.

## Transactions
| # | To | Data | Effect |
|---|---|---|---|
| 1 | CREATE2 proxy | `salt ‖ initCode` (plan `txs[0].data`) | Deploys FistagentMint (paused), which deploys FistagentToken and creates the empty official pair; shares #1–#1,100 recorded burned. |
| 2 | FistagentMint | `setPaused(false)` = 0x16c38b3c…00 | Minting opens at share #1,101; starts the 30-day clock. |

Execution, only after explicit user approval, per tx:
```
baw contract-call preview --binanceChainId 56 --from 0x49E6fb3812fdfD67eDfE17259f03CcbE59f39BCE --to <to> --value 0 --inputData <data> --json
baw contract-call execute --requestId <requestId> --json
```
After tx 1: verify source on BscScan + Sourcify (solc 0.8.24, optimizer 200, evm cancun, bytecode_hash none, cbor_metadata false;
token constructor args = USDT, Pancake V2 factory, V4 PoolManager, Infinity Vault). Set the API's `ALLOW_TO` to the mint address and
`DEPLOY_BLOCK` to the deploy block; set the real X handle (placeholder `FISTAGENT_X_TBD`) in site/config.js, index.html, whitepaper,
llms.txt, agent.md. Then tx 2.

## Money flow (the one change vs BNAGENT)
- Shares #1,101–#10,000: 20% → treasury, 80% parked (+40M FISTAGENT per share) for the pool.
- The tx reaching share 10,000 opens the pool with everything parked (7,120 USDT + 356B FISTAGENT), LP → dead, transfers unlocked.
- **After the pool opens, 100% of each mint payment goes to the treasury; mints add no liquidity.** (BNAGENT added 80% to the pool.)
- 30-day valve (unchanged): after 30 days without share 10,000, only the treasury may `withdrawUnfilled()` (0xa65c6326), repeatably;
  minting continues; never after the pool opens.

## Social signer reuse
Reusing 0x66EC…C199 is safe for replay: the EIP-712 domain includes the contract name ("FistagentMint") and `verifyingContract`,
so a BNAGENT voucher cannot be used on FISTAGENT and vice versa. Trade-off: one key now controls quota grants for both projects; if
it leaks, both can be over-granted social quota (+1 per task per Agent ID, max 3). The FISTAGENT API needs the same key in its
`SOCIAL_SIGNER_KEY` env (keystore stays in the BNAGENT repo's gitignored secrets/; not copied). A fresh signer can be used instead by
setting `SOCIAL_SIGNER=<addr>` when running BuildPlan (addresses change).

## Local rehearsal (no mainnet)
`test/local-fork/deploy-local.sh` replays tx 1 + tx 2 on a local anvil fork (impersonated treasury) so the API tests can read a deployed
FISTAGENT: `RPC=LOG_RPC=http://127.0.0.1:8545 DEPLOY_BLOCK=<block> node test/server/api.test.mjs`.
