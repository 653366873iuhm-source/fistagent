// FISTAGENT site configuration. NOT DEPLOYED YET: mint/token/pair are the planned CREATE2 addresses from deploy/bsc-mainnet-plan.json
// (salt keccak256("FISTAGENT.mint.v1"), social signer 0x66EC…C199, treasury 0x8663…d8AE). The site reads paused/supply live from the mint contract.
window.FISTAGENT_CONFIG = {
  chainId: 56,
  rpc: ["https://bsc-dataseed.bnbchain.org", "https://bsc-rpc.publicnode.com", "https://bsc-dataseed1.binance.org"],
  mint: "0x2c2787710Ec2B3D6b37b8936b8753982654aB4B3",   // FistagentMint
  token: "0xe252Cd16af4D41D7C01120e1d76c61683068fd15",  // FistagentToken
  pair: "0xdc6aCFe3dB5FB73f24E0de6E950a3743f67a277D",   // PancakeSwap FISTAGENT/USDT pair (mint.pair())
  usdt: "0x55d398326f99059fF775485246999027B3197955",
  agentRegistry: "0x60B9262456dE011F7d15a54CdD8c48bAaa8B022F",
  treasury: "0x866396d4aee9467b67194431bdbDdE8E8044d8AE",
  explorer: "https://bscscan.com",
  repo: "https://github.com/653366873iuhm-source/fistagent",
  site: "https://fistagent.onrender.com/",
  // Binance Agentic Wallet QR login proxy (server/ in the repo, Render web service). The mint contract address must be added to
  // its ALLOW_TO env var after deployment, otherwise mint previews are refused (USDT approve is always allowed).
  agentApi: "https://fistagent-api.onrender.com/api/agent-wallet",
  // Same API service: /api/social (task vouchers), /api/leaderboard; pinged on page load to wake the free instance.
  api: "https://fistagent-api.onrender.com",
  // Social tasks: handles are placeholders until decided.
  social: {
    x: "FISTAGENT_X_TBD", // https://x.com/FISTAGENT_X_TBD (without @)
  },
};
