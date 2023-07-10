// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

import { TestBase } from "../utils/TestBase.sol";

contract Assertions is TestBase {

    /**************************************************************************************************************************************/
    /*** Maple Token Invariants                                                                                                         ***/
    /**************************************************************************************************************************************/

    // TODO Are these invariants needed? Can we reuse existing ERC20 invariants?

    // Invariant A: ∑balanceOf(account) == totalSupply
    function assert_mapleToken_invariant_A(address mapleToken) internal { }

    // etc.
    function assert_mapleToken_invariant_B(address mapleToken) internal { }

    /**************************************************************************************************************************************/
    /*** Emergency Module Invariants                                                                                                    ***/
    /**************************************************************************************************************************************/

    // TODO: Is there any state to assert here?

    /**************************************************************************************************************************************/
    /*** Inflation Module Invariants                                                                                                    ***/
    /**************************************************************************************************************************************/

    // Verifies the integrity of the linked list of windows by traversing it from the start and ensuring the last window can be reached:
    // Invariant A (v1): traverseFrom(zeroWindowId) == lastScheduledWindowId
    // Invariant A (v2): traverseFrom(lastClaimedWindowId) == lastScheduledWindowId
    function assert_inflationModule_invariant_A(address inflationModule) internal { }

    // Verify the size of the linked list of windows is not off the charts.
    // Invariant B (v1): countWindowsFrom(zeroWindowId) <= maximumWindows
    // Invariant B (v1): countWindowsFrom(lastClaimedWindowId) <= maximumWindows
    // Invariant B (v3): lastScheduledWindowId <= maximumWindows
    function assert_inflationModule_invariant_B(address inflationModule) internal { }

    // Verify the last scheduled window is the last one in the linked list.
    // Invariant C: lastScheduledWindow.nextWindowId == 0
    function assert_inflationModule_invariant_C(address inflationModule) internal { }

    // Verify all windows are ordered in strictly ascending order:
    // Invariant D: ∑window(window.windowStart < nextWindow.windowStart)
    function assert_inflationModule_invariant_D(address inflationModule) internal { }

    // Verify all window issuance rates are lower than the maximum issuance rate.
    // Invariant E: ∑window(window.issuanceRate <= maximumIssuanceRate)
    function assert_inflationModule_invariant_E(address inflationModule) internal { }

    // Verify future tokens can not be claimed.
    // Invariant F: block.timestamp >= lastClaimed
    function assert_inflationModule_invariant_F(address inflationModule) internal { }

    // Verify the calculation of how many tokens are claimable at the current time.
    // Invariant G: claimable(block.timestamp) == manual calculation
    function assert_inflationModule_invariant_Gs(address inflationModule) internal { }

}
