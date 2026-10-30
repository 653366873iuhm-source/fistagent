#!/bin/sh
# Local FISTAGENT API (server/index.mjs) on :10777 for the site tests, reading chain state from the local anvil fork
# (test/local-fork/deploy-local.sh). Social signer key = the dedicated signer 0x66EC…C199, decrypted from its keystore
# (BNAGENT repo secrets/, gitignored; read-only) into this process's env only. Never printed, never committed.
KS_DIR=${SIGNER_KEYSTORE_DIR:-/workspace/work/bnagent/secrets}
K=$(/workspace/work/foundry/cast wallet decrypt-keystore --keystore-dir "$KS_DIR" social-signer --unsafe-password "$(cat "$KS_DIR/social-signer.password")" 2>/dev/null | grep -oE '0x[0-9a-fA-F]{64}' | tail -1)
[ -z "$K" ] && { echo "no key"; exit 1; }
cd "$(dirname "$0")/../.."
export NO_PROXY=127.0.0.1,localhost no_proxy=127.0.0.1,localhost
PORT=10777 RPC=${LOCAL_RPC:-http://127.0.0.1:8545} LOG_RPC=${LOCAL_RPC:-http://127.0.0.1:8545} DEPLOY_BLOCK=${DEPLOY_BLOCK:-130643000} \
  BINDX_NO_RESTORE=1 BINDX_EXPORT_KEY=local-test-export-key-0123456789abcdef SOCIAL_SIGNER_KEY=$K \
  ALLOW_TO=0x2c2787710Ec2B3D6b37b8936b8753982654aB4B3 setsid nohup node server/index.mjs > /tmp/fist-signer.log 2>&1 &
sleep 2; curl -s localhost:10777/ | head -c 300; echo
