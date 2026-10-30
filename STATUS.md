# FISTAGENT — STATUS (2026-10-30 ~18:45 CST)

FISTAGENT = exact clone of BNAGENT v2 (bnagent repo @ ea0c4c0) with ONE mechanism change (user 2026-10-30 17:39 CST):
**after the pool opens at share 10,000, 100% of each mint payment goes to the treasury** (no LP added by mints; buyer still gets
its tokens at 99% of the pool price). Before 10,000: 20% treasury / 80% parked → pool at 10,000, unchanged. Details: docs/JAGER-DIFF.md (top).

## State: BUILT LOCALLY, NOT DEPLOYED, NOT PUBLISHED
- No mainnet tx, nothing signed, no Render service, no GitHub repo/push, no X account.
- Planned (CREATE2, salt keccak256("FISTAGENT.mint.v1"), treasury 0x8663…d8AE, social signer 0x66EC…C199):
  mint 0x2c2787710Ec2B3D6b37b8936b8753982654aB4B3 · token 0xe252Cd16af4D41D7C01120e1d76c61683068fd15 · pair 0xdc6aCFe3dB5FB73f24E0de6E950a3743f67a277D.
- Deploy gas (eth_estimateGas, mainnet, 2026-10-30): 8,710,108 (≈0.00044 BNB at 0.05 gwei). Plan: deploy/bsc-mainnet-plan.json, docs/DEPLOY.md.
- Treasury/admin defaults to the BNAGENT treasury (iuhm.ai) — the user must confirm before deploy.

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
