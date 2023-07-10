// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

import { TestBase } from "../utils/TestBase.sol";

contract Assertions is TestBase {

    /**************************************************************************************************************************************/
    /*** Maple Token Invariants                                                                                                         ***/
    /**************************************************************************************************************************************/

    // TODO Are these invariants needed? Can we reuse existing ERC20 invariants?
    // Invariant A: ∑balanceOf(account) == totalSupply
    // etc.

    /**************************************************************************************************************************************/
    /*** Emergency Module Invariants                                                                                                    ***/
    /**************************************************************************************************************************************/

    // TODO: Is there any state to assert here?

    /**************************************************************************************************************************************/
    /*** Inflation Module Invariants                                                                                                    ***/
    /**************************************************************************************************************************************/

    // Verifies the integrity of the linked list of windows by traversing it from the start and ensuring the last window can be reached.
    // Invariant A (v1): traverseFrom(zeroWindowId) == lastScheduledWindowId
    // Invariant A (v2): traverseFrom(lastClaimedWindowId) == lastScheduledWindowId

    // Verify the zero index window is the first window.
    // Invariant B (v1): zeroWindow.windowStart == 0
    // Invariant B (v2): zeroWindow.windowStart == block.timestamp

    // Verify the zero index window is not issuing any tokens.
    // Invariant C: zeroWindow.issuanceRate == 0

    // Verify the size of the linked list of windows is within limits.
    // Invariant D (v1): countWindowsFrom(zeroWindowId) <= maximumWindows
    // Invariant D (v1): countWindowsFrom(lastClaimedWindowId) <= maximumWindows
    // Invariant D (v3): lastScheduledWindowId <= maximumWindows

    // Verify the last scheduled window is the last one in the linked list.
    // Invariant E: lastScheduledWindow.nextWindowId == 0

    // Verify all windows are ordered in strictly ascending order by ids:
    // Invariant F: ∑window(window.windowId < window.nextWindowId)

    // Verify all windows are ordered in strictly ascending order by timestamps:
    // Invariant G: ∑window(window.windowStart < nextWindow.windowStart)

    // Verify all window issuance rates are lower than the maximum issuance rate.
    // Invariant H: ∑window(window.issuanceRate <= maximumIssuanceRate)

    // Verify tokens can only be claimed up to the current time.
    // Invariant I: lastClaimedTimestamp <= block.timestamp

    // Verify the window of the last claim is set correctly based on the timestamp of the last claim.
    // Invariant J: windowOf(lastClaimedTimestamp) == lastClaimedWindowId

    // Verify the calculation of how many tokens are claimable at the current time.
    // Invariant K: claimable(block.timestamp) == manual calculation

}
