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

    uint32 public lastMinted;  // Timestamp of the last time tokens were issued.

    Window[] public windows;  // Windows of time and their associated issuance rates that define the inflation schedule.

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

    // Mints tokens from the time of the last mint up until the current time.
    // Tokens are minted separately for each window according to their issuance rates.
    function mint() external returns (uint256 amountMinted_) {
        amountMinted_ = mintable(lastMinted, lastMinted = uint32(block.timestamp));

        IERC20Like(token).mint(IGlobalsLike(globals).mapleTreasury(), amountMinted_);
    }

    // Calculates how many tokens have been or will be minted between the given timestamps.
    function mintable(uint32 from_, uint32 to_) public view returns (uint256 amount_) {
        uint256 windowsLength_ = windows.length;

        for (uint256 windowId_; windowId_ < windowsLength_; windowId_++) {
            Window memory window_     = windows[windowId_];
            uint256 windowEnd_        = windowId_ != windowsLength_ - 1 ? windows[windowId_ + 1].start : type(uint256).max;
            uint256 issuanceInterval_ = _calculateOverlap(.start, windowEnd_, from_, to_);

            amount_ += _vestTokens(window_.issuanceRate, issuanceInterval_);
        }
    }

    // Sets a new schedule some time in the future (can't schedule retroactively).
    function schedule(Window[] memory windows_) external onlyGovernor {
        _validateWindows(windows_);

        // Find the window from which the new windows will be inserted.
        uint256 windowsLength_     = windows.length;
        uint256 insertionWindowId_ = _findWindow(windows_[0].start, windowsLength_);

        _updateSchedule(insertionWindowId_, windowsLength_, windows_);
    }

    function windowCount() external view returns (uint256 windowCount_) {
        windowCount_ = windows.length;
    }

    /**************************************************************************************************************************************/
    /*** Internal Functions                                                                                                             ***/
    /**************************************************************************************************************************************/

    function _calculateOverlap(uint256 start_, uint256 end_, uint256 from_, uint256 to_) internal pure returns (uint256 overlap_) {
        overlap_ = _max(0, _min(end_, to_) - _max(start_, from_));
    }

    function _findWindow(uint32 start_, uint256 windowsLength_) internal view returns (uint256 windowId_) {
        for (; windowId_ < windowsLength_; windowId_++)
            if (start_ <= windows[windowId_].start) break;
    }

    function _max(uint256 a_, uint256 b_) internal pure returns (uint256 max_) {
        max_ = a_ > b_ ? a_ : b_;
    }

    function _min(uint256 a_, uint256 b_) internal pure returns (uint256 min_) {
        min_ = a_ < b_ ? a_ : b_;
    }

    function _updateSchedule(uint256 startingWindowId_, uint256 oldWindowsLength_, Window[] memory newWindows_) internal {
        uint256 newWindowsLength_ = startingWindowId_ + newWindows_.length;

        for (uint256 offset_; offset_ < newWindows_.length; offset_++) {
            uint256 windowId_     = startingWindowId_ + offset_;
            Window memory window_ = newWindows_[offset_];

            if (windowId_ >= oldWindowsLength_) windows.push(window_);
            else windows[windowId_] = window_;
        }

        if (newWindowsLength_ >= oldWindowsLength_) return;

        for (uint256 windowsToPop_ = oldWindowsLength_ - newWindowsLength_; windowsToPop_ > 0; windowsToPop_--)
            windows.pop();
    }

    function _validateWindows(Window[] memory windows_) internal view {
        require(windows_.length > 0,                  "IM:VW:NO_WINDOWS");
        require(windows_[0].start >= block.timestamp, "IM:VW:OUT_OF_DATE");

        for (uint256 index_ = 1; index_ < windows_.length; index_++)
            require(windows_[index_].start > windows_[index_ - 1].start, "IM:VW:OUT_OF_ORDER");
    }

    function _vestTokens(uint256 rate_, uint256 interval_) internal pure returns (uint256 amount_) {
        amount_ = rate_ * interval_ / PRECISION;
    }

}
