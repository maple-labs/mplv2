// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

import { IInflationModule } from "../../contracts/interfaces/IInflationModule.sol";

import { TestBase } from "../utils/TestBase.sol";

contract Assertions is TestBase {

    /**************************************************************************************************************************************/
    /*** Maple Token Invariants                                                                                                         ***/
    /**************************************************************************************************************************************/

    // TODO: Are these invariants needed? Can we reuse existing ERC20 invariants?
    // NOTE: ∑balanceOf(account) == totalSupply, etc.

    /**************************************************************************************************************************************/
    /*** Emergency Module Invariants                                                                                                    ***/
    /**************************************************************************************************************************************/

    // TODO: Is there any state to assert here?

    /**************************************************************************************************************************************/
    /*** Inflation Module Invariants                                                                                                    ***/
    /**************************************************************************************************************************************/

    /**
     *  @notice Asserts the linked list of windows can be traversed from start to end.
     *  @dev    Invariant: traverseFrom(zeroWindowId) == lastScheduledWindowId
     *  @param  module Address of the inflation module.
     */
    function assert_inflationModule_invariant_A(IInflationModule module) internal {
        uint16 windowId;

        while (true) {
            ( uint16 nextWindowId, , ) = module.windows(windowId);

            if (nextWindowId == 0) break;

            windowId = nextWindowId;
        }

        assertEq(windowId, module.lastScheduledWindowId(), "Can't reach the last scheduled window.");
    }

    /**
     *  @notice Asserts the last claimed window is contained in the linked list.
     *  @dev    Invariant: windows.contains(lastClaimedWindow)
     *  @param  module Address of the inflation module.
     */
    function assert_inflationModule_invariant_B(IInflationModule module) internal {
        uint16 windowId;

        while (true) {
            if (windowId == module.lastClaimedWindowId()) return;

            ( uint16 nextWindowId, , ) = module.windows(windowId);

            if (nextWindowId == 0) break;

            windowId = nextWindowId;
        }

        assertTrue(false, "Last claimed window is unreachable.");
    }

    /**
     *  @notice Asserts the zero index window is the first starting window.
     *  @dev    Invariant: zeroWindow.windowStart == 0
     *  @param  module Address of the inflation module.
     */
    function assert_inflationModule_invariant_C(IInflationModule module) internal {
        ( , uint32 windowStart, ) = module.windows(0);

        assertEq(windowStart, 0, "First window starting time is invalid.");
    }

    /**
     *  @notice Asserts the zero index window is not issuing any tokens.
     *  @dev    Invariant: zeroWindow.issuanceRate == 0
     *  @param  module Address of the inflation module.
     */
    function assert_inflationModule_invariant_D(IInflationModule module) internal {
        ( , , uint208 issuanceRate ) = module.windows(0);

        assertEq(issuanceRate, 0, "First window starting time is invalid.");
    }

    /**
     *  @notice Asserts the size of the linked list of windows is within limits.
     *  @dev    Invariant (v1): countWindowsFrom(zeroWindowId) <= maximumWindows
     *          Invariant (v2): countWindowsFrom(lastClaimedWindowId) <= maximumWindows
     *          Invariant (v3): lastScheduledWindowId <= maximumWindows
     *  @param  module Address of the inflation module.
     */
    function assert_inflationModule_invariant_E(IInflationModule module) internal {
        // TODO: Is this invariant is needed. Should the maximum number of windows be defined by the contract or enforced operationally?
    }

    /**
     *  @notice Asserts the last scheduled window is the last one in the linked list.
     *  @dev    Invariant: lastScheduledWindow.nextWindowId == 0
     *  @param  module Address of the inflation module.
     */
    function assert_inflationModule_invariant_F(IInflationModule module) internal {
        ( , uint32 nextWindowId, ) = module.windows(module.lastScheduledWindowId());

        assertEq(nextWindowId, 0, "Last scheduled window is not the last window.");
    }

    /**
     *  @notice Asserts all window identifiers are in strictly ascending order.
     *  @dev    Invariant: ∑window(windowId < window.nextWindowId)
     *  @param  module Address of the inflation module.
     */
    function assert_inflationModule_invariant_G(IInflationModule module) internal {
        uint16 windowId;

        while (true) {
            ( uint16 nextWindowId, , ) = module.windows(windowId);

            if (nextWindowId == 0) break;

            assertLt(windowId, nextWindowId, "Windows identifiers are not in strictly ascending order.");

            windowId = nextWindowId;
        }
    }

    /**
     *  @notice Asserts all window timestamps are in strictly ascending order.
     *  @dev    Invariant: ∑window(window.windowStart < nextWindow.windowStart)
     *  @param  module Address of the inflation module.
     */
    function assert_inflationModule_invariant_H(IInflationModule module) internal {
        uint16 windowId;

        while (true) {
            ( uint16 nextWindowId, uint32 windowStart, ) = module.windows(windowId);

            if (nextWindowId == 0) break;

            ( , uint32 nextWindowStart, ) = module.windows(nextWindowId);

            assertLt(windowStart, nextWindowStart, "Windows timestamps are not in strictly ascending order.");

            windowId = nextWindowId;
        }
    }

    /**
     *  @notice Asserts all window issuance rates are lower or equal than the maximum issuance rate.
     *  @dev    Invariant: ∑window(window.issuanceRate <= maximumIssuanceRate)
     *  @param  module Address of the inflation module.
     */
    function assert_inflationModule_invariant_I(IInflationModule module) internal {
        // TODO: Is this invariant is needed. Should the maximum issuance rate be defined by the contract or enforced operationally?

        uint16 windowId;

        while (true) {
            ( uint16 nextWindowId, , uint208 issuanceRate ) = module.windows(windowId);

            assertLe(issuanceRate, module.maximumIssuanceRate(), "Issuance rate is over the maximum limit.");

            if (nextWindowId == 0) break;

            windowId = nextWindowId;
        }
    }

    /**
     *  @notice Assert tokens can only be claimed up to the current time.
     *  @dev    Invariant: lastClaimedTimestamp <= block.timestamp
     *  @param  module Address of the inflation module.
     */
    function assert_inflationModule_invariant_J(IInflationModule module) internal {
        assertLe(module.lastClaimedTimestamp(), block.timestamp, "Last claimed timestamp is greater than the current time.");
    }

    /**
     *  @notice Assert the window of the last claim is set correctly based on the timestamp of the last claim.
     *  @dev    Invariant: windowOf(lastClaimedTimestamp) == lastClaimedWindowId
     *  @param  module Address of the inflation module.
     */
    function assert_inflationModule_invariant_K(IInflationModule module) internal {
        // TODO
    }

    /**
     *  @notice Assert the calculation of how many tokens are claimable at the current time is correct.
     *  @dev    Invariant: claimable(block.timestamp) == manual calculation
     *  @param  module Address of the inflation module.
     */
    function assert_inflationModule_invariant_L(IInflationModule module) internal {
        // NOTE: There shouldn't be any rounding errors here since we're not using precision.
    }

}
