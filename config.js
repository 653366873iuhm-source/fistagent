// FISTAGENT site configuration. DEPLOYED on BSC mainnet (tx 0x371fe25e…30f3, block 130677714); mint/token/pair below are live (minting paused until the treasury unpauses)
// (salt keccak256("FISTAGENT.mint.v1"), social signer 0x66EC…C199, treasury 0x49E6…9BCE). The site reads paused/supply live from the mint contract.
window.FISTAGENT_CONFIG = {
  chainId: 56,
  rpc: ["https://bsc-dataseed.bnbchain.org", "https://bsc-rpc.publicnode.com", "https://bsc-dataseed1.binance.org"],
  mint: "0xdDD8af1D1C9513D6eB5F4C017516360B26955c26",   // FistagentMint
  token: "0x7acDcE948Dc6F9185D96b8D1af80284C9a3c71c3",  // FistagentToken
  pair: "0xf375Def1f8f60Bf52A2a8D4309498B1FCE45C01B",   // PancakeSwap FISTAGENT/USDT pair (mint.pair())
  usdt: "0x55d398326f99059fF775485246999027B3197955",
  agentRegistry: "0x60B9262456dE011F7d15a54CdD8c48bAaa8B022F",
  treasury: "0x49E6fb3812fdfD67eDfE17259f03CcbE59f39BCE",
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
