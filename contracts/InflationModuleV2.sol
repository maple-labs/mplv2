// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

import { IERC20Like, IGlobalsLike } from "./interfaces/Interfaces.sol";

// TODO: Add interface (with struct?), events, NatSpec.
// TODO: Define which state variables should be publicly exposed.
// TODO: Check what issuance rate precision is good enough for MPL.
// TODO: Check if precision should be a constructor parameter.
// TODO: Huge IR could cause overflows. ACL `issue()` or set maximum IR?
// TODO: Should the inflation module be a proxy instead? Probably not.
// TODO: Check uint types and storage slot packing.
// TODO: Optimize `mintable()` for less storage reads and don't always iterate through entire array.
// TODO: Add invariant for all windows being in strictly increasing order.

contract InflationModule {

    struct Window {
        uint32  start;         // Timestamp that defines when vesting starts. Vesting lasts until the next window (or forever).
        uint224 issuanceRate;  // Rate at which tokens will be vested during the window (zero represents no vesting).
    }

    uint256 public constant PRECISION = 1e30;  // Precision of the issuance rate.

    address public immutable globals;  // Address of the `MapleGlobals` contract.
    address public immutable token;    // Address of the `MapleToken` contract.

    uint32 public lastIssued;  // Timestamp of the last time tokens were issued.

    Window[] public windows;  // Windows that define the inflation schedule.

    modifier onlyGovernor {
        require(msg.sender == IGlobalsLike(globals).governor(), "IM:NOT_GOVERNOR");

        _;
    }

    constructor(address globals_, address token_) {
        globals = globals_;
        token   = token_;
    }

    /**************************************************************************************************************************************/
    /*** External Functions                                                                                                             ***/
    /**************************************************************************************************************************************/

    function mintable(uint32 from_, uint32 to_) public view returns (uint256 amount_) {
        uint256 windowsLength_ = windows.length;

        for (uint256 windowId_; windowId_ < windowsLength_; windowId_++) {
            Window memory window_     = windows[windowId_];
            uint256 windowEnd_        = windowId_ != windowsLength_ - 1 ? windows[windowId_ + 1].start : type(uint256).max;
            uint256 issuanceInterval_ = _calculateOverlap(window_.start, windowEnd_, from_, to_);

            amount_ += _vestTokens(window_.issuanceRate, issuanceInterval_);
        }
    }

    // Mints tokens from the time of the last mint up until the current time.
    // Tokens are minted separately for each window according to their issuance rates.
    function mint() external returns (uint256 amountMinted_) {
        amountMinted_ = mintable(lastIssued, lastIssued = uint32(block.timestamp));

        IERC20Like(token).mint(IGlobalsLike(globals).mapleTreasury(), amountMinted_);
    }

    // Sets a new schedule some time in the future (can't schedule retroactively).
    function schedule(Window[] memory windows_) external onlyGovernor {
        _validateWindows(windows_);

        // Find the window from which the new windows will be inserted.
        uint256 windowsLength_     = windows.length;
        uint256 insertionWindowId_ = _findWindow(windows_[0].start, windowsLength_);

        _updateSchedule(insertionWindowId_, windowsLength_, windows_);
    }

    /**************************************************************************************************************************************/
    /*** Internal Functions                                                                                                             ***/
    /**************************************************************************************************************************************/

    function _calculateOverlap(
        uint256 windowStart_,
        uint256 windowEnd_,
        uint256 from_,
        uint256 to_
    )
        internal pure returns (uint256 overlap_)
    {
        overlap_ = _max(0, _min(windowEnd_, to_) - _max(windowStart_, from_));
    }

    // 0 - 1 - A - 3 - 4 - B - 6 - 7 - 8
    // 0 - 1 - 2 - 3 - C - 5 - D - 7 - 8

    function _findWindow(uint32 issuanceStart_, uint256 windowsLength_) internal view returns (uint256 windowId_) {
        for (; windowId_ < windowsLength_; windowId_++)
            if (issuanceStart_ <= windows[windowId_].start) break;
    }

    function _max(uint256 a_, uint256 b_) internal pure returns (uint256 max_) {
        max_ = a_ > b_ ? a_ : b_;
    }

    function _min(uint256 a_, uint256 b_) internal pure returns (uint256 min_) {
        min_ = a_ < b_ ? a_ : b_;
    }

    function _updateSchedule(uint256 startingWindowId_, uint256 oldWindowsLength_, Window[] memory newWindows_) internal {
        for (uint256 offset_; offset_ < newWindows_.length; offset_++)
            windows[startingWindowId_ + offset_] = newWindows_[offset_];

        uint256 newWindowsLength_ = startingWindowId_ + newWindows_.length;

        if (newWindowsLength_ > oldWindowsLength_) return;

        for (uint256 windowsToPop_ = oldWindowsLength_ - newWindowsLength_; windowsToPop_ > 0; windowsToPop_--)
            windows.pop();
    }

    function _validateWindows(Window[] memory windows_) internal view {
        // TODO: Check it's not an empty array.
        // TODO: Check first window starts at `block.timestamp` or later.
        // TODO: Check all following windows start at strictly increasing dates.
    }

    function _vestTokens(uint256 rate_, uint256 interval_) internal pure returns (uint256 amount_) {
        amount_ = rate_ * interval_ / PRECISION;
    }

}
