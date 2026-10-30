# FISTAGENT — STATUS (2026-10-30 ~18:45 CST)

FISTAGENT = exact clone of BNAGENT v2 (bnagent repo @ ea0c4c0) with ONE mechanism change (user 2026-10-30 17:39 CST):
**after the pool opens at share 10,000, 100% of each mint payment goes to the treasury** (no LP added by mints; buyer still gets
its tokens at 99% of the pool price). Before 10,000: 20% treasury / 80% parked → pool at 10,000, unchanged. Details: docs/JAGER-DIFF.md (top).

## State: DEPLOYED ON BSC MAINNET, MINTING PAUSED (2026-10-30)
- Deploy tx 0x371fe25ef197a25fffde067060d6f818700555d2f4fd5ebf2fe70665a26030f3, block 130677714, status 1.
- Mint 0xdDD8af1D1C9513D6eB5F4C017516360B26955c26 · Token 0x7acDcE948Dc6F9185D96b8D1af80284C9a3c71c3 · Pair 0xf375Def1f8f60Bf52A2a8D4309498B1FCE45C01B.
- Treasury allin168.ai 0x49E6fb3812fdfD67eDfE17259f03CcbE59f39BCE. paused() = true. setPaused(false) only on the user's explicit command.
- Source verified on Sourcify (full match, mint + token, 2026-10-30 22:07 CST).
- No project X account: site shows no X link/handle and no FOLLOW task (user 2026-10-30).
- GitHub: https://github.com/653366873iuhm-source/fistagent (main). Render: static `fistagent`, API `fistagent-api`.

## Tests (docs/test-results.txt)
- Forge fork tests: 29/29 (26 ported from BNAGENT + 3 new test_Fist*).
- API: 39/39 against a local anvil fork with the plan replayed (test/local-fork/deploy-local.sh).
- Site: headless (test/site/site.test.js), SITE_RPC pointed at the same anvil fork.

## Brand
- Logo traced from the user's reference (gold #F5B21B circle, white glyph), made symmetric and de-wobbled, dot = exact circle
  (tools/make_logo_fist.py): site/assets/fistagent-mark.svg/.png, favicon-fist.svg + favicon-fist-32/180/512.png, fistagent-lockup.png
  (Space Grotesk Bold cream wordmark, same layout as BNAGENT), og-fist.png, logo-fist-preview.png; mark.svg = same mark (wallet button icon).
- Site CSS/palette unchanged from BNAGENT.

## Before publishing (open items)
1. Confirm treasury (and social signer reuse vs a fresh signer) → rebuild plan if either changes (addresses change).
2. X handle: placeholder `FISTAGENT_X_TBD` in site/config.js, index.html, whitepaper, llms.txt, agent.md, tests.
3. Site/llms/agent copy says "minting is live / deployed, source verified" (BNAGENT wording) — true only after tx 1 + verify + tx 2.
4. Create Render static + API services (API env: SOCIAL_SIGNER_KEY, ALLOW_TO=mint, DEPLOY_BLOCK, BINDX_EXPORT_KEY), GitHub repo, workflows
   (.github/workflows/deploy.yml has a `$RENDER_SERVICE_IDS_FISTAGENT_TBD` placeholder instead of BNAGENT's service ids).
