#!/usr/bin/env bash
source ./.env

make -C certora munged-simple

# Script to run certora prover, assumes you have the prover cli setup locally
certoraRun certora/munged-simple/RecapitalizationModule.sol certora/helpers/GlobalsHelper.sol certora/helpers/MapleTokenHelper.sol \
--verify RecapitalizationModule:certora/specs/sanity.spec \
--loop_iter 3 \
--optimistic_loop
