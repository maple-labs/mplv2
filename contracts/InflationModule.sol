// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

import { IERC20Like, IGlobalsLike } from "./interfaces/Interfaces.sol";

contract InflationModule {

    uint256 constant public HUNDRED_PERCENT = 1e6;
    uint256 constant public PERIOD          = 365 days;

    address public immutable globals;
    address public immutable token;

    uint128 public rate;         // Yearly rate, in basis points. 1e6 = 100%
    uint40  public periodStart;
    uint40  public lastUpdated;
    uint256 public supply;

    constructor(address token_, address globals_, uint128 rate_) {
        token   = token_;
        globals = globals_;

        rate = rate_;
    }

    function setRate(uint128 rate_) external {
        // Timelock?
        require(msg.sender == IGlobalsLike(globals).governor(), "IM:SR:NOT_GOVERNOR");

        // If the period is ongoing, do a claim before changing the rate
        if (periodStart != 0) claim();

        rate = rate_;
    }

    function start() external {
        require(msg.sender == IGlobalsLike(globals).governor(), "IM:S:NOT_GOVERNOR");

        periodStart = uint40(block.timestamp);
        lastUpdated = uint40(block.timestamp);
        supply      = IERC20Like(token).totalSupply();
    }

    function claim() public {
        require(periodStart != 0, "IM:C:NOT_STARTED");

        ( uint256 amount, uint256 newSupply, uint256 newPeriodStart ) = _dueTokensAt(block.timestamp);

        lastUpdated = uint40(block.timestamp);
        periodStart = uint40(newPeriodStart);
        supply      = newSupply;

        // Mint
        IERC20Like(token).mint(IGlobalsLike(globals).mapleTreasury(), amount);
    }


    /**************************************************************************************************************************************/
    /*** Internal Functions                                                                                                             ***/
    /**************************************************************************************************************************************/

    function _dueTokensAt(uint256 timestamp) internal view returns (uint256 amount_, uint256 newSupply_, uint256 newPeriodStart_) {
        // Save variables to stack
        newSupply_      = supply;
        newPeriodStart_ = periodStart;

        if (timestamp < lastUpdated) return (amount_, newSupply_, newPeriodStart_);

        uint256 rate_        = rate;
        uint256 periodEnd_   = periodStart + PERIOD;
        uint256 lastUpdated_ = lastUpdated;

        // If it's past the period end, there's a need to compound the supply
        if (timestamp > periodEnd_) {
            // First, get the amount from lastUpdated to when the period ended.
            amount_      = _interestFor(periodEnd_ - lastUpdated_, newSupply_, rate_);
            lastUpdated_ = periodEnd_;

            // Since at least full period has passed, the new supply is snapshotted and compounded.
            // Won't be precisely at the end of period, so there will be some amount of time where the supply is not updated, but that's fine.
            //  Adding `amount_` because tokens haven't been minted yet.
            newSupply_ = IERC20Like(token).totalSupply() + amount_;

            // Get the amounts of full periods that have passed. On most situations, this will be 0.
            // There's no way to snapshot the supply at the end of each period, so the last known supply is used.
            uint256 fullPeriods_ = (timestamp - lastUpdated_) / PERIOD;
            uint256 period_      = fullPeriods_;

            // There is a more optimized version of this, using the compound interest formula, but realistically this code should never
            // run, therefore a simpler version is used, to avoid using a scaled exponentiation function.
            while (period_ > 0) {
                // For every full period, the full interest is added to the amount, and the supply is compounded.
                uint256 periodAmount = _interestFor(PERIOD, newSupply_, rate_);

                amount_    += periodAmount;
                newSupply_ += periodAmount;

                period_--;
            }

            // Update the lastUpdated_ and newPeriodStart_ variables.
            newPeriodStart_ = uint40(periodStart + ((fullPeriods_ + 1) * PERIOD));
            lastUpdated_    = newPeriodStart_;
        }

        // This will handle both the case where the lastUpdates is within the same period and that the interval from
        // the new periodStart to the timestamp.
        amount_ += _interestFor(timestamp - lastUpdated_, newSupply_, rate_);
    }

    function _interestFor(uint256 interval_, uint256 supply_, uint256 rate_) internal pure returns (uint256 amount) {
        amount = (supply_ * rate_ * interval_ ) / (PERIOD * HUNDRED_PERCENT);
    }

}
