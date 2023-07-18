#!/bin/bash

source ./.env

# Note to add --broadcast flag when sending
# To use a different wallet index, add --mnemonic-indexes n where n is the index
# and you have to use --mnemonics foo as foundry enforces a mnemonic flag requirement when using mnemonic-indexes
# see https://github.com/foundry-rs/foundry/issues/5179

FOUNDRY_PROFILE=production

# Run an instance of anvil forking mainnet so transactions can be sent and persisted.
# the `> /dev/null 2>&1 &` is to run the process in the background ignoring logs
anvil -f $ETH_RPC_URL > /dev/null 2>&1 &
anvil_pid=$!

echo "Creating local testnet for deployment" 
sleep 5 # Wait for anvil to start

# Deploy the token first, listing to the anvil rpc endpoint
forge script \
  --rpc-url "http://localhost:8545" -vvvv \
  --sender $ETH_SENDER \
  "scripts/DeployToken.s.sol:DeployToken" \
  --broadcast --unlocked #--mnemonics foo --mnemonic-indexes 3 --ledger

# Deploy the migrator next, building on top of the token deployment 
forge script \
  --rpc-url "http://localhost:8545" -vvvv \
  --sender $ETH_SENDER \
  "scripts/DeployMigrator.s.sol:DeployMigrator" \
  --broadcast --unlocked # --mnemonics foo --mnemonic-indexes 3 --ledger

# Kill the anvil process
kill $anvil_pid
