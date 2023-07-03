// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

import { IERC20Like, IGlobalsLike } from "./interfaces/Interfaces.sol";

// TODO: Add interface (with struct?), events, NatSpec.
// TODO: Define which state variables should be publicly exposed.
// TODO: Check what issuance rate precision is good enough for MPL.
// TODO: Check if precision should be a constructor parameter.
// TODO: Huge IR could cause overflows. ACL `issue()` or set maximum IR?
// TODO: Should the inflation module be a proxy instead? Probably not.
// TODO: Optimize `mintable()` for less storage reads and don't always iterate through entire array.
// TODO: Add invariant for all windows being in strictly increasing order.
// TODO: Add invariant test that checks the current amount of issuable tokens is not beyond a certain limit.
// TODO: If struct optimization is not relevant, should order of variables be alphabetical or whatever is most intuitive?
// TODO: Check uint types and storage slot packing.
// TODO: Check if windows are order in strictly ascending order when scheduling? Prevent duplicate windows from being passed?

contract InflationModule {

    struct Window {
        uint16  windowId;      // Identifier of the window (stored redundantly for convenience).
        uint16  nextWindowId;  // Identifier of the window that takes effect after this one (zero if there is none).
        uint32  windowStart;   // Timestamp that marks when the window starts. It lasts until the start of the next window (or forever).
        uint256 issuanceRate;  // Defines the rate at which tokens will be minted (zero indicates no minting).
    }

    uint256 public constant PRECISION = 1e30;  // Precision of the issuance rate.

    address public immutable globals;  // Address of the `MapleGlobals` contract.
    address public immutable token;    // Address of the `MapleToken` contract.

    uint16 public currentWindowId;  // Identifier of the last window during which tokens were issued.
    uint16 public windowCounter;    // Number of windows created so far.

    uint32 public lastMinted;  // Stores the timestamp when tokens were last minted.

    mapping(uint16 => Window) public windows;  // Maps identifiers to schedules (effectively an implementation of a linked list).

    modifier onlyGovernor {
        require(msg.sender == IGlobalsLike(globals).governor(), "IM:NOT_GOVERNOR");

        _;
    }

    constructor(address globals_, address token_) {
        globals = globals_;
        token   = token_;

        windowCounter = 1;
    }

    /**************************************************************************************************************************************/
    /*** External Functions                                                                                                             ***/
    /**************************************************************************************************************************************/

    // Mint tokens from the time of the last mint up until the current time.
    // The tokens are minted separately for each window according to it's issuance rate.
    function mint() external returns (uint256 mintableAmount_, uint16 currentWindowId_) {
        ( mintableAmount_, currentWindowId_ ) = mintable(uint32(block.timestamp));

        lastMinted      = uint32(block.timestamp);
        currentWindowId = currentWindowId_;

        if (mintableAmount_ > 0) {
            IERC20Like(token).mint(IGlobalsLike(globals).mapleTreasury(), mintableAmount_);
        }
    }

    function mintable(uint32 to_) public view returns (uint256 mintableAmount_, uint16 currentWindowId_) {
        uint32 lastMinted_ = lastMinted;
        currentWindowId_   = currentWindowId;

        if (to_ <= lastMinted_) return (0, currentWindowId_);

        while (true) {
            Window memory currentWindow_ = windows[currentWindowId_];
            Window memory nextWindow_    = windows[currentWindow_.nextWindowId];

            // Check if the current window is still active.
            bool isWindowActive_ = currentWindow_.nextWindowId == 0 ? true : to_ < nextWindow_.windowStart;

            // If it's still active mint up to the current time, otherwise mint only up to the start of the next window.
            uint256 vestingInterval_ = (isWindowActive_ ? to_ : nextWindow_.windowStart) - lastMinted_;

            mintableAmount_ += currentWindow_.issuanceRate * vestingInterval_ / PRECISION;

            // End the minting here if the current window is still active.
            if (isWindowActive_) break;

            // Otherwise repeat the entire process for the next window.
            lastMinted_      = nextWindow_.windowStart;
            currentWindowId_ = nextWindow_.windowId;
        }
    }

    // Sets a new schedule some time in the future (can't schedule retroactively).
    // Can be called on a yearly basis to "compound" the issuance rate or update it on demand via governance.
    // Can also be used to delete the schedule by setting the issuance rate to zero.
    function schedule(uint32[] memory windowStarts_, uint256[] memory issuanceRates_) external onlyGovernor {
        require(windowStarts_.length > 0 && issuanceRates_.length > 0, "IM:S:NO_WINDOW");
        require(windowStarts_.length == issuanceRates_.length,         "IM:S:LENGTH_MISMATCH");

        for (uint32 index_ = 0; index_ < windowStarts_.length; index_++) {
            _scheduleWindow(windowStarts_[index_], issuanceRates_[index_]);
        }

    }

    /**************************************************************************************************************************************/
    /*** Internal Functions                                                                                                             ***/
    /**************************************************************************************************************************************/

    // Search windows from start to end to find where the new window should be inserted.
    function _findInsertionPoint(uint32 windowStart_) internal view returns (Window memory window_) {
        window_ = windows[0];

        while (true) {
            Window memory nextWindow_ = windows[window_.nextWindowId];

            if (window_.nextWindowId == 0 || windowStart_ < nextWindow_.windowStart) break;

            window_ = nextWindow_;
        }
    }

    function _scheduleWindow(uint32 windowStart_, uint256 issuanceRate_) internal {
        require(windowStart_ >= block.timestamp, "IM:S:OUT_OF_DATE");

        ( Window memory window_ ) = _findInsertionPoint(windowStart_);

        // If the window already exists then replace it.
        if (windowStart_ == window_.windowStart) {
            windows[window_.windowId].issuanceRate = issuanceRate_;
        }

        // Otherwise create a new window and insert it.
        else {
            uint16 newWindowId_ = windows[window_.windowId].nextWindowId = windowCounter++;
            windows[newWindowId_] = Window(newWindowId_, window_.nextWindowId, windowStart_, issuanceRate_);
        }
    }

}
