#!/usr/bin/env bash
source ./.env
# Script to run certora prover, assumes you have the prover cli setup locally
certoraRun contracts/InflationModule.sol certora/helpers/GlobalsHelper.sol certora/helpers/MapleTokenHelper.sol \
--verify InflationModule:certora/InflationModule.spec \
--optimistic_loop
