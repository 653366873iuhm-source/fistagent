// FISTAGENT site configuration. v2 mint DEPLOYED on BSC mainnet (tx 0x3bea79c8…c89a, block 130809409); minting open since 2026-10-31 14:34 CST.
// v2: shares #1-#2,000 free (claimFree(), one per .ai Agent ID), #2,001-#10,000 = 1 USDT (100% parked for the pool).
// Social signer 0x66EC…C199, treasury 0x07Ed…9353. The site reads paused/supply live from the mint contract.
window.FISTAGENT_CONFIG = {
  chainId: 56,
  rpc: ["https://bsc-rpc.publicnode.com", "https://bsc-dataseed.bnbchain.org", "https://bsc-dataseed1.binance.org"],
  mint: "0x4738427479ff49D0f151e9069ceCfaadaEd35B30",   // FistagentMint
  token: "0x8E4e86ACfafcB2242B71f75e58fB627F1deaC2c1",  // FistagentToken
  pair: "0x3A1C63c12297BECD3Ed3E0e36E5990d4251eC27c",   // PancakeSwap FISTAGENT/USDT pair (mint.pair())
  usdt: "0x55d398326f99059fF775485246999027B3197955",
  agentRegistry: "0x60B9262456dE011F7d15a54CdD8c48bAaa8B022F",
  treasury: "0x07Ed634a873D3aFCf7079616262D897C31b19353",
  explorer: "https://bscscan.com",
  repo: "https://github.com/653366873iuhm-source/fistagent",
  site: "https://fistagent.onrender.com/",
  // Binance Agentic Wallet QR login proxy (server/ in the repo, Render web service). The mint contract address must be added to
  // its ALLOW_TO env var after deployment, otherwise mint previews are refused (USDT approve is always allowed).
  agentApi: "https://fistagent-api.onrender.com/api/agent-wallet",
  // Same API service: /api/social (task vouchers), /api/leaderboard; pinged on page load to wake the free instance.
  api: "https://fistagent-api.onrender.com",
  // Social: no project X account yet (user 2026-10-30) -> no X link/handle and no FOLLOW task on the site. Set x: "<handle>" to add them.
  social: {
    x: "",
  },
};
