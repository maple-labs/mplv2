#!/usr/bin/env bash

# Script to run certora prover, assumes you have the prover cli setup locally
certoraRun contracts/InflationModule.sol:InflationModule certora/helpers/GlobalsHelper.sol:GlobalsHelper \
--verify InflationModule:certora/InflationModule.spec
