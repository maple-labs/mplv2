// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

import { IGlobalsLike, IMapleTokenLike } from "./interfaces/Interfaces.sol";

// TODO: Add interface (with struct), events, NatSpec.
// TODO: Add a view function that returns the current schedule as an array of windows.

contract InflationModule {

    struct Window {
        uint16  nextWindowId;  // Identifier of the window that takes effect after this one (zero if there is none).
        uint32  windowStart;   // Timestamp that marks when the window starts. It lasts until the start of the next window (or forever).
        uint208 issuanceRate;  // Defines the rate (per second) at which tokens will be issued (zero indicates no issuance).
    }

    address public immutable token;    // Address of the `MapleToken` contract.

    uint16 public newWindowId;  // Identifier that will be assigned to the next scheduled window.

    uint32 public lastClaimedTimestamp;  // Iimestamp of the last time tokens were claimed.
    uint16 public lastClaimedWindowId;   // Identifier of the window during which tokens were last claimed.

    // TODO: What if this is set to a value lower than an already existing issuance rate for any of the windows?
    uint208 public maximumIssuanceRate;  // Maximum issuance rate allowed for any window (to prevent overflows).

    mapping(uint16 => Window) public windows;  // Maps identifiers to windows (effectively an implementation of a linked list).

    modifier onlyGovernor {
        require(msg.sender == IGlobalsLike(_globals()).governor(), "IM:NOT_GOVERNOR");

        _;
    }

    modifier onlyScheduled(bytes32 functionId_) {
        IGlobalsLike globals_ = IGlobalsLike(_globals());
        bool isScheduledCall_ = globals_.isValidScheduledCall(msg.sender, address(this), functionId_, msg.data);

        require(isScheduledCall_, "IM:NOT_SCHEDULED");

        globals_.unscheduleCall(msg.sender, functionId_, msg.data);

        _;
    }

    constructor(address token_) {
        token = token_;
        newWindowId = 1;
        maximumIssuanceRate = 1e18;
    }

    /**************************************************************************************************************************************/
    /*** External Functions                                                                                                             ***/
    /**************************************************************************************************************************************/

    // Claims tokens from the time of the last claim up until the current time.
    function claim() external returns (uint256 amountClaimed_) {
        ( uint16 lastClaimableWindowId_, uint256 claimableAmount_ ) = _claimable(lastClaimedWindowId, lastClaimedTimestamp);

        require(claimableAmount_ > 0, "IM:C:ZERO_MINT");

        lastClaimedTimestamp = uint32(block.timestamp);
        lastClaimedWindowId  = lastClaimableWindowId_;

        IMapleTokenLike(token).mint(IGlobalsLike(_globals()).mapleTreasury(), amountClaimed_ = claimableAmount_);
    }

    // Schedules new windows that define when tokens will be issued.
    function schedule(uint32[] memory windowStarts_, uint208[] memory issuanceRates_) external onlyGovernor onlyScheduled("IM:SCHEDULE") {
        _validateWindows(windowStarts_, issuanceRates_);

        // Find at which point in the linked list to insert the new windows.
        uint16 insertionWindowId_ = _findInsertionPoint(windowStarts_[0]);
        uint16 newWindowId_       = newWindowId;

        windows[insertionWindowId_].nextWindowId = newWindowId_;

        // Create all the new windows and link them up to each other.
        uint16 newWindowCount_ = uint16(windowStarts_.length);

        for (uint16 index_; index_ < newWindowCount_; ++index_) {
            windows[newWindowId_ + index_] = Window({
                nextWindowId: index_ < newWindowCount_ - 1 ? newWindowId_ + index_ + 1 : 0,
                windowStart:  windowStarts_[index_],
                issuanceRate: issuanceRates_[index_]
            });
        }

        newWindowId += newWindowCount_;
    }

    // Sets a new limit to the maximum issuance rate allowed for any window.
    function setMaximumIssuanceRate(uint192 maximumIssuanceRate_) external onlyGovernor onlyScheduled("IM:SMIR") {
        maximumIssuanceRate = maximumIssuanceRate_;
    }

    /**************************************************************************************************************************************/
    /*** Internal Functions                                                                                                             ***/
    /**************************************************************************************************************************************/

    // Calculates how many tokens can be claimed from the time of the last claim up until the current time.
    function _claimable(
        uint16 lastClaimedWindowId_,
        uint32 lastClaimedTimestamp_
    )
        internal view returns (
            uint16  lastClaimableWindowId_,
            uint256 claimableAmount_
        )
    {
        Window memory window_ = windows[lastClaimedWindowId_];
        Window memory nextWindow_;

        while (lastClaimedTimestamp_ < block.timestamp) {
            uint32 windowStart_ = _max(lastClaimedTimestamp, window_.windowStart);
            uint32 windowEnd_   = uint32(block.timestamp);

            bool isLastWindow_ = window_.nextWindowId == 0;

            if (!isLastWindow_) {
                nextWindow_ = windows[window_.nextWindowId];
                windowEnd_  = _min(windowEnd_, nextWindow_.windowStart);
            }

            claimableAmount_ += window_.issuanceRate * (windowEnd_ - windowStart_);

            if (isLastWindow_) break;

            lastClaimedTimestamp_ = windowEnd_;
            lastClaimedWindowId_ = window_.nextWindowId;

            window_ = nextWindow_;
        }

        lastClaimableWindowId_ = lastClaimedWindowId_;
    }

    // Search windows from start to end to find where the new window should be inserted.
    function _findInsertionPoint(uint32 windowStart_) internal view returns (uint16 windowId_) {
        Window memory window_ = windows[lastClaimedWindowId];

        while (true) {
            uint16 nextWindowId_ = window_.nextWindowId;

            if (nextWindowId_ == 0) break;

            window_ = windows[nextWindowId_];

            if (windowStart_ <= window_.windowStart) break;

            windowId_ = nextWindowId_;
        }
    }

    function _globals() public view returns (address globals_) {
        globals_ = IMapleTokenLike(token).globals();
    }

    function _max(uint32 a_, uint32 b_) internal pure returns (uint32 max_) {
        max_ = a_ > b_ ? a_ : b_;
    }

    function _min(uint32 a_, uint32 b_) internal pure returns (uint32 min_) {
        min_ = a_ < b_ ? a_ : b_;
    }

    function _validateWindows(uint32[] memory windowStarts_, uint208[] memory issuanceRates_) internal view {
        require(windowStarts_.length > 0 && issuanceRates_.length > 0, "IM:VW:EMPTY_ARRAY");
        require(windowStarts_.length == issuanceRates_.length,         "IM:VW:LENGTH_MISMATCH");
        require(windowStarts_[0] >= block.timestamp,                   "IM:VW:OUT_OF_DATE");

        for (uint256 index_ = 1; index_ < windowStarts_.length; ++index_) {
            require(windowStarts_[index_] > windowStarts_[index_ - 1], "IM:VW:OUT_OF_ORDER");
        }

        uint208 maximumIssuanceRate_ = maximumIssuanceRate;

        for (uint256 index_; index_ < issuanceRates_.length; ++index_) {
            require(issuanceRates_[index_] <= maximumIssuanceRate_, "IM:VW:OUT_OF_BOUNDS");
        }
    }

}
