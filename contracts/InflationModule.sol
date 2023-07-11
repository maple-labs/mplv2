// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

import { IGlobalsLike, IMapleTokenLike } from "./interfaces/Interfaces.sol";

import { IInflationModule } from "./interfaces/IInflationModule.sol";

contract InflationModule is IInflationModule {

    struct Window {
        uint16  nextWindowId;  // Identifier of the window that takes effect after this one (zero if there is none).
        uint32  windowStart;   // Timestamp that marks when the window starts. It lasts until the start of the next window (or forever).
        uint208 issuanceRate;  // Defines the amount of tokens per second that will be issued (zero indicates no issuance).
    }

    address public immutable token;

    uint208 public immutable maximumIssuanceRate;

    uint16 public lastClaimedWindowId;
    uint16 public lastScheduledWindowId;

    uint32 public lastClaimedTimestamp;

    mapping(uint16 => Window) public windows;

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

    constructor(address token_, uint208 maximumIssuanceRate_) {
        token               = token_;
        maximumIssuanceRate = maximumIssuanceRate_;
    }

    /**************************************************************************************************************************************/
    /*** External Functions                                                                                                             ***/
    /**************************************************************************************************************************************/

    function claim() external returns (uint256 amountClaimed_) {
        (
            uint16  lastClaimableWindowId_,
            uint256 claimableAmount_
        ) = _claimable(lastClaimedWindowId, lastClaimedTimestamp, uint32(block.timestamp));

        require(claimableAmount_ > 0, "IM:C:ZERO_CLAIM");

        lastClaimedTimestamp = uint32(block.timestamp);
        lastClaimedWindowId  = lastClaimableWindowId_;

        emit Claimed(claimableAmount_, lastClaimableWindowId_);

        IMapleTokenLike(token).mint(IGlobalsLike(_globals()).mapleTreasury(), amountClaimed_ = claimableAmount_);
    }

    function claimable(uint32 to_) external view returns (uint256 claimableAmount_) {
        uint32 lastClaimedTimestamp_ = lastClaimedTimestamp;
        uint16 lastClaimableWindowId_;

        require(to_ > lastClaimedTimestamp_, "IM:C:OUT_OF_DATE");

        ( lastClaimableWindowId_, claimableAmount_ ) = _claimable(lastClaimedWindowId, lastClaimedTimestamp, to_);
    }

    function schedule(uint32[] memory windowStarts_, uint208[] memory issuanceRates_) external onlyGovernor onlyScheduled("IM:SCHEDULE") {
        _validateWindows(windowStarts_, issuanceRates_);

        // Find at which point in the linked list to insert the new windows.
        uint16 insertionWindowId_ = _findInsertionPoint(windowStarts_[0]);
        uint16 newWindowId_       = lastScheduledWindowId + 1;

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

        lastScheduledWindowId += newWindowCount_;

        emit WindowsScheduled(insertionWindowId_, windowStarts_, issuanceRates_);
    }

    /**************************************************************************************************************************************/
    /*** Internal Functions                                                                                                             ***/
    /**************************************************************************************************************************************/

    function _claimable(
        uint16 windowId_,
        uint32 from_,
        uint32 to_
    )
        internal view returns (
            uint16  lastClaimableWindowId_,
            uint256 claimableAmount_
        )
    {
        Window memory window_ = windows[windowId_];
        Window memory nextWindow_;

        while (from_ < to_) {
            bool isLastWindow_ = window_.nextWindowId == 0;

            if (!isLastWindow_) {
                nextWindow_ = windows[window_.nextWindowId];
            }

            bool isCurrentWindow_ = isLastWindow_ ? true : to_ < nextWindow_.windowStart;

            uint32 windowEnd_ = isCurrentWindow_ ? to_ : nextWindow_.windowStart;

            claimableAmount_ += window_.issuanceRate * (windowEnd_ - from_);

            if (isCurrentWindow_) break;

            from_     = windowEnd_;
            windowId_ = window_.nextWindowId;
            window_   = nextWindow_;
        }

        lastClaimableWindowId_ = windowId_;
    }

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

    function _validateWindows(uint32[] memory windowStarts_, uint208[] memory issuanceRates_) internal view {
        require(windowStarts_.length > 0 && issuanceRates_.length > 0, "IM:VW:EMPTY_ARRAY");
        require(windowStarts_.length == issuanceRates_.length,         "IM:VW:LENGTH_MISMATCH");
        require(windowStarts_[0] >= block.timestamp,                   "IM:VW:OUT_OF_DATE");

        for (uint256 index_ = 0; index_ < windowStarts_.length - 1; ++index_) {
            require(windowStarts_[index_] < windowStarts_[index_ + 1], "IM:VW:OUT_OF_ORDER");
        }

        for (uint256 index_; index_ < issuanceRates_.length; ++index_) {
            require(issuanceRates_[index_] <= maximumIssuanceRate, "IM:VW:OUT_OF_BOUNDS");
        }
    }

}
