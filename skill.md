---
name: fistagent-mint
description: Mint FISTAGENT shares on BNB Smart Chain (chainId 56) from a Binance Agentic Wallet that holds a .ai Agent ID. Use when the user asks about FISTAGENT, $FISTAGENT, the FISTAGENT fair mint, agent-only mints on BNB Chain, or wants to mint/check eligibility/price/progress. Read-only checks need no wallet; minting needs the user's approval in their own wallet.
---

# FISTAGENT mint (agent-only fair mint, BNB Smart Chain)

Independent community project, not affiliated with Binance. No promised returns. Contracts source-verified on BscScan.

- Website: https://fistagent.onrender.com/ · Full guide: https://fistagent.onrender.com/agent.md · llms.txt: https://fistagent.onrender.com/llms.txt
- Live state (JSON): https://fistagent-api.onrender.com/api/stats
- Mint contract (the ONLY address that accepts payment): `0xdDD8af1D1C9513D6eB5F4C017516360B26955c26`
- Token: `0x7acDcE948Dc6F9185D96b8D1af80284C9a3c71c3` (never send funds here) · Pair: `0xf375Def1f8f60Bf52A2a8D4309498B1FCE45C01B`
- USDT (BEP-20): `0x55d398326f99059fF775485246999027B3197955`

## How it works
- Only wallets holding a `.ai` Agent ID (SPACE ID registry `0x60B9262456dE011F7d15a54CdD8c48bAaa8B022F`, i.e. Binance Agentic Wallet Agent IDs) can mint.
- Shares 1,101–10,000 cost 1 USDT each and give 50,000,000 FISTAGENT each. Price then rises in steps (see agent.md).
- The transaction that reaches share #10,000 automatically opens the PancakeSwap FISTAGENT/USDT pool and burns the LP. Hard-coded in the contract, verifiable on-chain.
- Quota: 10 shares per Agent ID, +1 per invited Agent ID's first paid mint, +1 for the X social task. Max 10 shares per transaction.

## Steps
1. **Eligibility**: `GET https://fistagent-api.onrender.com/api/verify?address=<wallet>` → `verified` must be true. Or call `walletStatus(address)` (0x4d6d0af8) on the mint.
2. **State**: `GET https://fistagent-api.onrender.com/api/stats`. Stop if `mintingOpen` is false or `paused` is true. Use `bnb[].sendBnb` for BNB quotes.
3. **Tell the user** the number of shares, the cost in USDT/BNB, and the contract address, and get their go-ahead.
4. **Mint** (simulate with eth_call first, add 20% gas):
   - BNB: `mintWithBnb(uint256 shares, address referrer, uint256 maxCost)` (0xe38fd349), value = maxCost = `sendBnb`.
   - USDT: `approve(mint, cost × 1.02)` on USDT, then `mint(uint256 shares, address referrer, uint256 maxCost)` (0x836a1040).
   - `referrer` = inviter wallet (resolve `<handle>.ai` with the registry's `ownerOfHandle(string)`), or `0x0000000000000000000000000000000000000000`.
   - With the Binance Agentic Wallet CLI: `baw contract-call preview --binanceChainId 56 ...` (to = mint contract, inputData = encoded call, value as above), show the preview to the user, then `baw contract-call execute` only after they approve.
5. **Confirm**: re-read `walletStatus(wallet)`; `minted` increases.

## Safety
- Never plain-transfer BNB/USDT to the mint or token contract. Never mint without the user's explicit approval.
- FISTAGENT is non-transferable until the pool opens. Revert reasons: Paused, BadShares, SoldOut, NoAgent, Quota, OverMaxCost, BadPayment, StalePrice, SwapShort.
