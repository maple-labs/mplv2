// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

import { IInflationModule } from "../../contracts/interfaces/IInflationModule.sol";

library Invariants {

    /**************************************************************************************************************************************/
    /*** Inflation Module Invariants                                                                                                    ***/
    /**************************************************************************************************************************************/

    /**
     *  @notice Asserts the linked list of windows can be traversed from start to end.
     *  @dev    Invariant: traverseFrom(zeroWindowId) == lastScheduledWindowId
     *  @param  module Address of the inflation module.
     */
    function assert_inflationModule_invariant_A(IInflationModule module) internal view {
        uint16 windowId;

        while (true) {
            ( uint16 nextWindowId, , ) = module.windows(windowId);

            if (nextWindowId == 0) break;

            windowId = nextWindowId;
        }

        require(windowId == module.lastScheduledWindowId(), "Can't reach the last scheduled window.");
    }

    /**
     *  @notice Asserts the last claimed window is contained in the linked list.
     *  @dev    Invariant: windows.contains(lastClaimedWindow)
     *  @param  module Address of the inflation module.
     */
    function assert_inflationModule_invariant_B(IInflationModule module) internal view {
        uint16 windowId;

        while (true) {
            if (windowId == module.lastClaimedWindowId()) return;

            ( uint16 nextWindowId, , ) = module.windows(windowId);

            require(nextWindowId != 0, "Last claimed window is unreachable.");

            windowId = nextWindowId;
        }
    }

    /**
     *  @notice Asserts the zero index window is the first starting window.
     *  @dev    Invariant: zeroWindow.windowStart == 0
     *  @param  module Address of the inflation module.
     */
    function assert_inflationModule_invariant_C(IInflationModule module) internal view {
        ( , uint32 windowStart, ) = module.windows(0);

        require(windowStart == 0, "Zero index window timestamp is invalid.");
    }

    /**
     *  @notice Asserts the zero index window is not issuing any tokens.
     *  @dev    Invariant: zeroWindow.issuanceRate == 0
     *  @param  module Address of the inflation module.
     */
    function assert_inflationModule_invariant_D(IInflationModule module) internal view {
        ( , , uint208 issuanceRate ) = module.windows(0);

        require(issuanceRate == 0, "Zero index window issuance rate is invalid.");
    }

    /**
     *  @notice Asserts the last scheduled window is the last one in the linked list.
     *  @dev    Invariant: lastScheduledWindow.nextWindowId == 0
     *  @param  module Address of the inflation module.
     */
    function assert_inflationModule_invariant_E(IInflationModule module) internal view {
        ( uint16 nextWindowId, , ) = module.windows(module.lastScheduledWindowId());

        require(nextWindowId == 0, "Last scheduled window is not the last window.");
    }

    /**
     *  @notice Asserts all window identifiers are in strictly ascending order.
     *  @dev    Invariant: ∑window(windowId < window.nextWindowId)
     *  @param  module Address of the inflation module.
     */
    function assert_inflationModule_invariant_F(IInflationModule module) internal view {
        uint16 windowId;

        while (true) {
            ( uint16 nextWindowId, , ) = module.windows(windowId);

            if (nextWindowId == 0) break;

            require(windowId < nextWindowId, "Window identifiers are not in strictly ascending order.");

            windowId = nextWindowId;
        }
    }

    /**
     *  @notice Asserts all window timestamps are in strictly ascending order.
     *  @dev    Invariant: ∑window(window.windowStart < nextWindow.windowStart)
     *  @param  module Address of the inflation module.
     */
    function assert_inflationModule_invariant_G(IInflationModule module) internal view {
        uint16 windowId;

        while (true) {
            ( uint16 nextWindowId, uint32 windowStart, ) = module.windows(windowId);

            if (nextWindowId == 0) break;

            ( , uint32 nextWindowStart, ) = module.windows(nextWindowId);

            require(windowStart < nextWindowStart, "Window timestamps are not in strictly ascending order.");

            windowId = nextWindowId;
        }
    }

    /**
     *  @notice Asserts tokens can only be claimed up to the current time.
     *  @dev    Invariant: lastClaimedTimestamp <= block.timestamp
     *  @param  module Address of the inflation module.
     */
    function assert_inflationModule_invariant_H(IInflationModule module, uint32 blockTimestamp) internal view {
        require(module.lastClaimedTimestamp() <= blockTimestamp, "Last claimed timestamp is greater than the current time.");
    }

    /**
     *  @notice Asserts the window of the last claim is set correctly based on the timestamp of the last claim.
     *  @dev    Invariant: windowOf(lastClaimedTimestamp) == lastClaimedWindowId
     *  @param  module Address of the inflation module.
     */
    function assert_inflationModule_invariant_I(IInflationModule module) internal view {
        ( uint16 nextWindowId, uint32 windowStart, ) = module.windows(module.lastClaimedWindowId());

        require(module.lastClaimedTimestamp() >= windowStart, "Last claimed winow is invalid.");

        if (nextWindowId == 0) return;

        ( , uint32 windowEnd, ) = module.windows(nextWindowId);

        require(module.lastClaimedTimestamp() < windowEnd, "Last claimed window is invalid.");
    }

}
