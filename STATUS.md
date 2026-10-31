# FISTAGENT — STATUS (2026-10-31 CST)

## State: v2 DEPLOYED ON BSC MAINNET, MINTING OPEN since 2026-10-31 14:34 CST
- Deploy tx 0x3bea79c84ca26250d6c58ddb605c31827bece03552c06e36aa23ed4c6cd5c89a, block 130809409.
- Mint 0x4738427479ff49D0f151e9069ceCfaadaEd35B30 · Token 0x8E4e86ACfafcB2242B71f75e58fB627F1deaC2c1 · Pair 0x3A1C63c12297BECD3Ed3E0e36E5990d4251eC27c.
- Treasury 0x07Ed634a873D3aFCf7079616262D897C31b19353 (user's wallet; tax receiver; only address that can call withdrawUnfilled()).
- Operator (deployer) 0x8d6cdA80e93322fAc57d917BAB1894a3411086f9: pause/unpause only. Social signer 0x66ECa9C28e4e4807e37C078b917e527DC85aC199 (unchanged).
- mintDeadline() = 1796020473 = 2026-11-30 14:34:33 CST.
- Source verified on BscScan and Sourcify (match), mint + token, 2026-10-31.
- v2 rules: #1–#2,000 free (claimFree, 1 per Agent ID); #2,001–#10,000 = 1 USDT, 100% parked; pool at 10,000 (8,000 USDT + 400B); then 100% to treasury.
- v1 mint (0xdDD8…5c26) is superseded; site, API, agent docs all point at v2.
- GitHub: https://github.com/653366873iuhm-source/fistagent (main). Render: static `fistagent`, API `fistagent-api`
  (env ALLOW_TO = v2 mint, DEPLOY_BLOCK = 130809409; MINT/TOKEN/PAIR default to v2 in code).

## Site
- While totalMinted < 2,000 the mint card shows "Claim free share" (claimFree(), value 0; disabled if no Agent ID or freeClaimed[id]);
  from 2,000 on the normal paid UI (1–10 shares, USDT/BNB).
- Agentic Wallet proxy preview accepts any calldata to the mint (incl. claimFree) with value 0.

## Tests
- API: node test/server/api.test.mjs (40/40 on 2026-10-31, live BSC reads).
- test/site/site.test.js still asserts v1 numbers (1,100 burned) and needs updating before reuse.
