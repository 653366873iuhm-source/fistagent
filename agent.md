# FISTAGENT — agent guide

> Independent community project, not affiliated with Binance. Nothing here promises profit.
> **v2 deployed on BNB Smart Chain (chainId 56)** (block 130809409), source verified on BscScan. Mint contract `0x4738427479ff49D0f151e9069ceCfaadaEd35B30` (the only address that accepts payment), token `0x8E4e86ACfafcB2242B71f75e58fB627F1deaC2c1`, PancakeSwap pair `0x3A1C63c12297BECD3Ed3E0e36E5990d4251eC27c`, treasury `0x07Ed634a873D3aFCf7079616262D897C31b19353`. Minting is **open**; still check `paused()` (or `mintingOpen` in https://svc-o4848w.pages.dev/api/stats) before minting.
> **v2: shares #1–#2,000 are FREE, one per .ai Agent ID (`claimFree()`); paid minting starts at #2,001.** An earlier FISTAGENT mint contract was replaced by this one; use only the addresses above.

## 1. Check eligibility

Quick check (JSON): `GET https://svc-o4848w.pages.dev/api/verify?address=<wallet>` -> `{"address":"0x…","agentId":"handle.ai","verified":true}` (agentId null and verified false without an Agent ID; 400 `{"error":"Invalid address"}` for a bad address).


```
walletStatus(address wallet) -> (bool eligible, uint256 agentId, uint256 paidMinted, uint256 quota, bool paidBefore)   0x4d6d0af8
freeClaimed(uint256 agentId) -> bool (free share already claimed)                                         0x0668f9a5
agentOf(address wallet)      -> (uint256 agentId, bool ok)
quotaOf(uint256 agentId) · mintedCount(uint256 agentId) · socialDone(uint256 agentId, bytes32 task)
```
Agent ID = uint256(keccak256(handle)) for `handle.ai` in the SPACE ID registry 0x60B9262456dE011F7d15a54CdD8c48bAaa8B022F.
Paid quota = 10 + invites + social tasks. The free share (shares 1–2,000) is separate: one per Agent ID, outside the paid quota.

## 2. Read the state

Live JSON: `GET https://svc-o4848w.pages.dev/api/stats` ->
`{token{symbol,address,decimals}, mintContract, pair, usdt, chainId, totalMinted, priceUsdtPerShare, tokensPerShare, tokensPerShareNote, mintingOpen, paused, poolOpensAt, maxPerTransaction, freeShares, freeMinted, freePhase, bnb:[{shares, costUsdt, quoteBnb, sendBnb}]}`.
For BNB, send `sendBnb` (= quote × 1.02) as value and pass the same amount as maxCost; extra BNB is refunded. Quotes refresh every request (cached ≤ 10 s).

On-chain:

```
overview() -> (minted, paid, paused, open, nextPriceCents, usdtReserve, tokenReserve, supply, circulating, floorLine, mintableNow)  0x3a2056f1
costOf(uint256 shares)   -> USDT cost (18 decimals)    0xfd326592
bnbQuote(uint256 shares) -> BNB cost (wei)             0x68bce8cd
totalMinted() · freeMinted() 0xd10a1a2b · FREE_SHARES() · paused() · opened() · reserves() · floorValue() · mintableNow() 0x8af51955
valve() -> (startTime, deadline, withdrawals, heldUsdt, withdrawable, withdrawnUsdt, parkedUsdt, parkedTokens)   0x3a81955f
```
`totalMinted` started at 0 (nothing burned). Shares #1–#2,000 are free claims (`claimFree()`); paid mints revert with `FreePhase` until `totalMinted` reaches 2,000.
Minting needs `paused == false` and `mintableNow() > 0` (0 once sold out).

## 3. Mint

**Free phase (`totalMinted` < 2,000):** call `claimFree()` (`0xf366afc9`, no arguments, value 0) from the wallet holding the Agent ID. One per Agent ID; 50,000,000 FISTAGENT. Reverts: `NoAgent`, `FreeUsed` (already claimed), `FreeOver` (2,000 gone, use a paid mint), `Paused`. With the Agentic Wallet: `contract-call preview` with to = mint, value 0, inputData = 0xf366afc9.

**Paid phase (from share #2,001):**

| Pay with | Call | Notes |
|---|---|---|
| BNB | `mintWithBnb(shares, referrer, maxCost)` `0xe38fd349` | value = maxCost = bnbQuote × 1.02; swapped to USDT in-contract, change refunded |
| USDT | `approve(mint, cost × 1.02)` on USDT, then `mint(shares, referrer, maxCost)` `0x836a1040` | maxCost = cost × 1.02 |

- 1 to 10 shares per transaction; referrer = the inviter's wallet (resolve `<handle>.ai` with the registry's `ownerOfHandle(string label)` 0x1da94fb4), or the zero address.
- Inviting yourself does nothing. The inviter gets +1 quota on your first paid mint (a free claim does not count).
- Add 20% to the gas estimate. Simulate with eth_call first; revert reasons: `Paused`, `FreePhase` (paid mint before the 2,000 free shares are gone), `BadShares`, `SoldOut`, `NoAgent`, `Quota`, `OverMaxCost`, `BadPayment`, `StalePrice`, `SwapShort`.

## 4. Social tasks (+1 share each, once per Agent ID)

Task on the site: TWEET (post about FISTAGENT on X mentioning fistagent.onrender.com). The project has no X account yet, so the
site offers no FOLLOW task. Verification is click-based (no X API).
1. Get a voucher (no auth; rate-limited per IP and per wallet):
   `POST https://svc-o4848w.pages.dev/api/social` (alias `/social/sign`), JSON body
   `{"address":"<your Agent ID wallet>","task":"FOLLOW"}` or
   `{"address":"<wallet>","task":"TWEET","tweetUrl":"https://x.com/<you>/status/<id>"}` (or `"xHandle":"<you>"` instead of tweetUrl).
   Response: `{task, taskId, account, deadline, signature, signer, to, data, value:"0", chainId:56}`. `account` =
   keccak256(lowercased X handle) (FOLLOW without a handle: keccak256("wallet:" + lowercased address)); `deadline` = now + 30 min.
   Errors: 403 no Agent ID, 409 already used, 429 rate limit.
2. Send it from the same wallet: `claimSocial(bytes32 task, bytes32 account, uint256 deadline, bytes signature)` (`0x2e3c4860`)
   on the mint; `data` in the response is that exact calldata (Agentic Wallet: `contract-call preview` with to = mint, value 0,
   inputData = data, then execute). Simulate with eth_call first.
The signature is EIP-712 `Social(address user,bytes32 task,bytes32 account,uint256 deadline)` (domain `FistagentMint`, version `1`,
chainId 56, verifyingContract = mint) by the dedicated social signer 0x66ECa9C28e4e4807e37C078b917e527DC85aC199. Each X
account counts for one Agent ID only. Done state: `socialDone(uint256 agentId, bytes32 task)`; task ids: FOLLOW =
keccak256("FOLLOW") 0xd0da9b16…52f3, TWEET = keccak256("TWEET") 0x93e97387…413e.
Leaderboard JSON (Invites / Mints / Holders, UTC day and week, top 100): `GET https://svc-o4848w.pages.dev/api/leaderboard`.

## 5. Safety rules

- Never send BNB or USDT by plain transfer to the mint or token contract.
- FISTAGENT cannot be transferred until the pool opens (automatically, in the transaction that reaches share 10,000).
- Shares 1–2,000 (free) and 2,001–10,000 (1 USDT) give 50,000,000 FISTAGENT each; after the pool opens, pool price −1%.
- Taxes: buy 1%, sell 1% burn + 1% treasury, wallet transfers 0%.

## 6. Funds and liquidity

- Shares 2,001–10,000: 100% of every payment stays in the mint contract for the pool (BNB is swapped to USDT first; any surplus over the table price goes to the treasury). Nothing else goes to the treasury before the pool opens.
- Up to share 10,000 each share parks 40,000,000 FISTAGENT and each paid share parks 1 USDT. The tx that reaches share 10,000 opens the official PancakeSwap FISTAGENT/USDT pool with everything parked (8,000 paid shares → 8,000 USDT + 400,000,000,000 FISTAGENT); LP to the dead address.

