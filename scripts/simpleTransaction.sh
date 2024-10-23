#!/bin/bash
# Needed to forward time to pass the timelock on a fork
source ./.env

curl -H "Content-Type: application/json" -X POST --data '{"jsonrpc":"2.0","method":"evm_increaseTime","params":[604900]}' $ETH_RPC_URL

curl -X POST $ETH_RPC_URL \
-H "Content-Type: application/json" \
-d '{
  "jsonrpc": "2.0",
  "method": "eth_sendTransaction",
  "params": [{
    "from": "0x763aC43aFEE020c2670dF03800541B76c8D87882",
    "to": "0x0000000000000000000000000000000000000000",
    "value": "0x1BC16D674EC80000",
    "gas": "0x5208",
    "gasPrice": "0x3B9ACA00"
  }],
  "id": 1
}'
