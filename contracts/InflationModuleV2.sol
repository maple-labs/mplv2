// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

import { IERC20Like, IGlobalsLike } from "./interfaces/Interfaces.sol";

// TODO: Add interface (with struct), events, NatSpec.
// TODO: Add invariant for all windows being in strictly increasing order.

contract InflationModule {

    struct Window {
        uint16  nextWindowId;  // Identifier of the window that takes effect after this one (zero if there is none).
        uint32  windowStart;   // Timestamp that marks when the window starts. It lasts until the start of the next window (or forever).
        uint208 issuanceRate;  // Defines the rate (per second) at which tokens will be issued (zero indicates no issuance).
    }

    address public immutable globals;  // Address of the `MapleGlobals` contract.
    address public immutable token;    // Address of the `MapleToken` contract.

    uint16 public currentWindowId;  // Identifier of the last window during which tokens were claimed.
    uint16 public windowCounter;    // Total number of new windows created so far.

    uint32 public lastClaimed;  // Iimestamp of the last time tokens were claimed.

    uint208 public maximumIssuanceRate;  // Maximum issuance rate allowed for any window (to prevent overflows).

    mapping(uint16 => Window) public windows;  // Maps identifiers to windows (effectively an implementation of a linked list).

    modifier onlyGovernor {
        require(msg.sender == IGlobalsLike(globals).governor(), "IM:NOT_GOVERNOR");

        _;
    }

    modifier onlyScheduled(bytes32 functionId_) {
        IGlobalsLike globals_ = IGlobalsLike(globals);
        bool isScheduledCall_ = globals_.isValidScheduledCall(msg.sender, address(this), functionId_, msg.data);

        require(isScheduledCall_, "IM:NOT_SCHEDULED");

        globals_.unscheduleCall(msg.sender, functionId_, msg.data);

        _;
    }

    constructor(address globals_, address token_) {
        globals = globals_;
        token   = token_;

        windowCounter = 1;
        maximumIssuanceRate = 1e18;
    }

    /**************************************************************************************************************************************/
    /*** External Functions                                                                                                             ***/
    /**************************************************************************************************************************************/

    // Claims tokens from the time of the last claim up until the current time.
    function claim() external returns (uint256 mintableAmount_, uint16 currentWindowId_) {
        ( mintableAmount_, currentWindowId_ ) = claimable(uint32(block.timestamp));

        lastClaimed     = uint32(block.timestamp);
        currentWindowId = currentWindowId_;

        if (mintableAmount_ > 0) {
            IERC20Like(token).mint(IGlobalsLike(globals).mapleTreasury(), mintableAmount_);
        }
    }

    // Calculates how many tokens can be claimed from the time of the last claim up until the specified time.
    function claimable(uint32 to_) public view returns (uint256 mintableAmount_, uint16 currentWindowId_) {
        uint32 lastClaimed_ = lastClaimed;
        currentWindowId_    = currentWindowId;

        if (to_ <= lastClaimed_) return (0, currentWindowId_);

        while (true) {
            Window memory currentWindow_ = windows[currentWindowId_];
            Window memory nextWindow_    = windows[currentWindow_.nextWindowId];

            // Check if the current window is still active.
            bool isWindowActive_ = currentWindow_.nextWindowId == 0 ? true : to_ < nextWindow_.windowStart;

            // If it's still active mint up to the current time, otherwise mint only up to the start of the next window.
            uint256 vestingInterval_ = (isWindowActive_ ? to_ : nextWindow_.windowStart) - lastClaimed_;

            mintableAmount_ += currentWindow_.issuanceRate * vestingInterval_;

            // End the minting here if the current window is still active.
            if (isWindowActive_) break;

            // Repeat the entire process for the next window.
            currentWindowId_ = currentWindow_.nextWindowId;
            lastClaimed_     = nextWindow_.windowStart;
        }
    }

    // Schedules new windows that define when tokens will be issued.
    function schedule(uint32[] memory windowStarts_, uint208[] memory issuanceRates_) external onlyGovernor onlyScheduled("IM:SCHEDULE") {
        _validateWindows(windowStarts_, issuanceRates_);

        // Find at which point in the linked list to insert the new windows.
        uint16 insertionWindowId_ = _findInsertionPoint(windowStarts_[0]);
        uint16 newWindowId_       = windowCounter;

        windows[insertionWindowId_].nextWindowId = newWindowId_;

        // Create all the new windows and link them up to each other.
        uint16 newWindowCount_ = uint16(windowStarts_.length);

        for (uint16 index_; index_ < newWindowCount_; index_++) {
            windows[newWindowId_ + index_] = Window({
                nextWindowId: index_ < newWindowCount_ - 1 ? newWindowId_ + index_ + 1 : 0,
                windowStart:  windowStarts_[index_],
                issuanceRate: issuanceRates_[index_]
            });
        }

        windowCounter += newWindowCount_;
    }

    // Sets a new limit to the maximum issuance rate allowed for any window.
    function setMaximumIssuanceRate(uint192 maximumIssuanceRate_) external onlyGovernor {
        maximumIssuanceRate = maximumIssuanceRate_;
    }

    /**************************************************************************************************************************************/
    /*** Internal Functions                                                                                                             ***/
    /**************************************************************************************************************************************/

    // Search windows from start to end to find where the new window should be inserted.
    function _findInsertionPoint(uint32 windowStart_) internal view returns (uint16 windowId_) {
        Window memory currentWindow_ = windows[windowId_];

        while (true) {
            Window memory nextWindow_ = windows[currentWindow_.nextWindowId];

            if (currentWindow_.nextWindowId == 0 || windowStart_ <= currentWindow_.windowStart) break;

            windowId_      = currentWindow_.nextWindowId;
            currentWindow_ = nextWindow_;
        }
    }

    function _validateWindows(uint32[] memory windowStarts_, uint208[] memory issuanceRates_) internal view {
        require(windowStarts_.length > 0 && issuanceRates_.length > 0, "IM:VW:EMPTY_ARRAY");
        require(windowStarts_.length == issuanceRates_.length,         "IM:VW:LENGTH_MISMATCH");
        require(windowStarts_[0] >= block.timestamp,                   "IM:VW:OUT_OF_DATE");

        for (uint256 index_ = 1; index_ < windowStarts_.length; index_++) {
            require(windowStarts_[index_] > windowStarts_[index_ - 1], "IM:VW:OUT_OF_ORDER");
        }

        uint208 maximumIssuanceRate_ = maximumIssuanceRate;

        for (uint256 index_; index_ < issuanceRates_.length; index_++) {
            require(issuanceRates_[index_] <= maximumIssuanceRate_, "IM:VW:OUT_OF_BOUNDS");
        }
    }

}
