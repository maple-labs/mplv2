#!/bin/bash

source ./.env

# Note to add --broadcast flag when sending
# To use a different wallet index, add --mnemonic-indexes n where n is the index
# and you have to use --mnemonics foo as foundry enforces a mnemonic flag requirement when using mnemonic-indexes
# see https://github.com/foundry-rs/foundry/issues/5179

FOUNDRY_PROFILE=production

# NOTE: Make sure that the computed addresses for mplv2 and migrator are corret for the given ETH_SENDER

# Deploy the token first, listing to mainnet rpc endpoint
forge script \
  --rpc-url $ETH_RPC_URL -vvvv \
  --sender $ETH_SENDER \
  "scripts/DeployToken.s.sol:DeployToken" \
  --broadcast --mnemonics foo --mnemonic-indexes 3 --ledger

# Deploy the migrator next, building on top of the token deployment 
forge script \
  --rpc-url $ETH_RPC_URL -vvvv \
  --sender $ETH_SENDER \
  "scripts/DeployMigrator.s.sol:DeployMigrator" \
  --broadcast --mnemonics foo --mnemonic-indexes 3 --ledger
