// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

import { IERC20Like, IGlobalsLike } from "./interfaces/Interfaces.sol";

contract InflationModule {

    uint256 constant public HUNDRED_PERCENT = 1e6;
    uint256 constant public SCALE           = 1e18;
    uint256 constant public PERIOD          = 365 days; 

    address public immutable globals;
    address public immutable token;

    uint256 supply;
    uint256 expectedPeriodSupply; // Saves the expected supply at the end of the period.
    uint128 rate; // Yearly rate, in basis points. 1e6 = 100%
    uint40  periodStart;
    uint40  lastUpdated;

    constructor(address _token, address _globals, uint128 rate_) {
        token   = _token;
        globals = _globals;

        rate = rate_;
    }

    function setRate(uint128 rate_) external {
        require(msg.sender == IGlobalsLike(globals).governor(), "IM:SR:NOT_GOVERNOR");

        // 

        rate = rate_;
    }

    function start() external {
        periodStart = uint40(block.timestamp);
        lastUpdated  = uint40(block.timestamp);

        supply = 11_000_000e18; // Starts with 11M tokens 

        expectedPeriodSupply = _getAccruedAmount(PERIOD, supply, rate);
    }

    // Withdraw tokens from inflation rate
    function withdraw() external {
        require(periodStart != 0, "IM:W:NOT_STARTED");

        uint256 periodEnd_   = periodStart + PERIOD;
        uint256 lastUpdated_ = lastUpdated;    
        uint256 supply_      = supply; 
        uint256 rate_        = rate;

        uint256 amount = 0;
        // It's past the timestamp when the principal should compound.
        if (block.timestamp > periodEnd_) {
            // Accrue last period's amount;
            amount       = _getAccruedAmount(periodEnd_ - lastUpdated_, supply_, rate_);
            lastUpdated_ = uint40(periodEnd_);

            // Compound the previous period supply for next period calculation. NOTE: What if rate changes mid period?
            supply_ += expectedPeriodSupply;

            uint256 fullPeriods_ = (block.timestamp - lastUpdated_) / PERIOD;
            uint256 period_      = fullPeriods_; 

            // There is a more optimized version of this, using the compound interest formula, but realistically this code should never
            // run, therefore a simpler version is used, to avoid using a scaled exponentiation function.
            while (period_ > 0) {
                uint256 periodAmount = _getAccruedAmount(PERIOD, supply_, rate_);
                amount  += periodAmount;
                supply_ += periodAmount;
                period_--;
            }
            
            lastUpdated_ = uint40(periodEnd_ + (fullPeriods_ * PERIOD)); 

            periodStart          = uint40(periodStart + (fullPeriods_ * PERIOD));
            supply               = supply_;
            expectedPeriodSupply = _getAccruedAmount(PERIOD, supply_, rate_);
        }
        
        // Accrue the amount for the current period
        amount += _getAccruedAmount(block.timestamp - lastUpdated_, supply_, rate_);

        lastUpdated = uint40(block.timestamp);

        // Mint
        IERC20Like(token).mint(IGlobalsLike(globals).mapleTreasury(), amount);
    }

    function _dueTokensFor() internal view returns (uint256 amount_) {

    }

    function _getAccruedAmount(uint256 interval_, uint256 supply_, uint256 rate_) internal pure returns (uint256 amount) {
        amount = (supply_ * rate_ * interval_ * SCALE) / (PERIOD * SCALE * HUNDRED_PERCENT);
    }

}
