// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

import { TestBase } from "../utils/TestBase.sol";

contract Assertions is TestBase {

    /**************************************************************************************************************************************/
    /*** Inflation Module Invariants                                                                                                    ***/
    /**************************************************************************************************************************************/

    // Invariant A: windows(lastWindowId).nextWindowId == 0
    function assert_inflationModule_invariant_A(address inflationModule) internal { }

    // Invariant C: traverseFrom(currentWindowId).nextWindowId == 0
    function assert_inflationModule_invariant_B(address inflationModule) internal { }

    // Invariant D: block.timestamp >= lastClaimed
    function assert_inflationModule_invariant_C(address inflationModule) internal { }

    // Invariant E: ∑window.windowStart < nextWindow.windowStart
    function assert_inflationModule_invariant_D(address inflationModule) internal { }

    // Invariant F: ∑window.issuanceRate <= maximumIssuanceRate
    function assert_inflationModule_invariant_E(address inflationModule) internal { }

    // Invariant G: claimable(lastClaimed, block.timestamp) == estimation
    function assert_inflationModule_invariant_F(address inflationModule) internal { }

    // Invariant H: size(linkedList) <= maximumWindows OR windowCounter <= maximumWindows
    function assert_inflationModule_invariant_G(address inflationModule) internal { }

    /**************************************************************************************************************************************/
    /*** Maple Token Invariants                                                                                                         ***/
    /**************************************************************************************************************************************/

    // Are these invariants even needed? Should we reuse existing ERC20 invariants?

    // Invariant A: ∑balanceOf(account) == totalSupply
    function assert_mapleToken_invariant_A(address mapleToken) internal { }

    // etc.
    function assert_mapleToken_invariant_B(address mapleToken) internal { }

}
