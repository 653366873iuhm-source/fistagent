#!/usr/bin/env bash
# Deploys FISTAGENT exactly as the plan says into a LOCAL anvil fork of BSC (never mainnet): the treasury is impersonated
# on anvil, tx 1 (CREATE2 deploy) and tx 2 (setPaused(false)) from deploy/bsc-mainnet-plan.json are replayed there.
# Start anvil first:  anvil --fork-url https://bsc-rpc.publicnode.com --chain-id 56 --port 8545
# Then point the API at it (RPC=LOG_RPC=http://127.0.0.1:8545) to run test/server/api.test.mjs against a deployed FISTAGENT.
set -euo pipefail
export NO_PROXY=127.0.0.1,localhost no_proxy=127.0.0.1,localhost
R=${LOCAL_RPC:-http://127.0.0.1:8545}
case "$R" in http://127.0.0.1*|http://localhost*) ;; *) echo "refusing: LOCAL_RPC must be a local anvil" >&2; exit 1;; esac
T=0x866396d4aee9467b67194431bdbDdE8E8044d8AE
cd "$(dirname "$0")/../.."
D=$(python3 -c "import json;print(json.load(open('deploy/bsc-mainnet-plan.json'))['txs'][0]['data'])")
U=$(python3 -c "import json;print(json.load(open('deploy/bsc-mainnet-plan.json'))['txs'][1]['data'])")
M=$(python3 -c "import json;print(json.load(open('deploy/bsc-mainnet-plan.json'))['expectedMint'])")
cast rpc --rpc-url $R anvil_impersonateAccount $T >/dev/null
cast rpc --rpc-url $R anvil_setBalance $T 0x56BC75E2D63100000 >/dev/null
cast send --rpc-url $R --unlocked --from $T 0x4e59b44847b379578588920cA78FbF26c0B4956C $D --gas-limit 12000000 | grep -E "^(status|gasUsed|blockNumber)"
cast send --rpc-url $R --unlocked --from $T $M $U | grep -E "^status"
echo "totalMinted $(cast call --rpc-url $R $M 'totalMinted()(uint256)')  paused $(cast call --rpc-url $R $M 'paused()(bool)')  pair $(cast call --rpc-url $R $M 'pair()(address)')"
