// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

import { IERC20Like, IGlobalsLike } from "./interfaces/Interfaces.sol";

import { console } from "../modules/forge-std/src/console.sol";

// TODO: Add interface (with struct?), events, NatSpec.
// TODO: Define which state variables should be publicly exposed.

contract InflationModule {

    // TODO: Add struct optimization?
    // TODO: If struct optimization is not relevant, should order of variables be alphabetical or whatever is most intuitive?
    // TODO: Could also include the schedule id (redundantly) since everything except the issuance rate can fit into one slot.
    struct Schedule {
        uint256 startingTime;    // Defines when token issuance begins and at which rate tokens will be issued.
        uint256 nextScheduleId;  // Issuance takes effect from the starting time of the schedule up until the next one (if it exists).
        uint256 issuanceRate;    // Defines the rate at which tokens will be issued (can be zero to stop issuance).
    }

    // TODO: Consider enforcing the issuance rate to always be a multiplier of the smallest unit of MPL to prevent all rounding errors.
    uint256 public constant PRECISION = 1e30;  // Precision of the issuance rate.

    address public immutable globals;  // Address of the MapleGlobals contract.
    address public immutable token;    // Address of the MapleToken contract.

    uint256 public lastIssued;      // Stores the timestamp when tokens were last issued.
    uint256 public lastScheduleId;  // Stores the identifier of the schedule during which tokens were last issued.
    uint256 public scheduleCount;   // Stores the number of schedules created so far.

    // TODO: If needed, optimize linked list operations: merging schedules with same issuance rates.
    mapping(uint256 => Schedule) public schedules;  // Maps identifiers to schedules (effectively an implementation of a linked list).

    modifier onlyGovernor {
        require(msg.sender == IGlobalsLike(globals).governor(), "IM:NOT_GOVERNOR");

        _;
    }

    // TODO: Should this module be a proxy instead?
    constructor(address globals_, address token_) {
        globals = globals_;
        token   = token_;

        // TODO: Should the schedules the first schedule have an index of `0` or `1`?
        // TODO: Should we explicitly create the first default non-issuing schedule? And would it be from `0` or `block.timestamp`?
    }

    /**************************************************************************************************************************************/
    /*** External Functions                                                                                                             ***/
    /**************************************************************************************************************************************/

    // TODO: Add invariant test that checks the current amount of issuable tokens is not beyond a certain limit.
    // TODO: Should the function parameters be `from` and `to` timestamps instead?
    function issuableAt(uint256 timestamp_) public view returns (uint256 issuableAmount_, uint256 lastScheduleId_) {
        uint256 lastIssued_ = lastIssued;
        lastScheduleId_     = lastScheduleId;

        require(timestamp_ >= lastIssued_, "IM:IA:OUT_OF_DATE");

        while (true) {
            Schedule memory currentSchedule_ = schedules[lastScheduleId_];
            Schedule memory nextSchedule_    = schedules[currentSchedule_.nextScheduleId];

            // Check if the current schedule is still active.
            bool isScheduleActive = currentSchedule_.nextScheduleId == 0 ? true : timestamp_ < nextSchedule_.startingTime;

            // If it's still active vest up to the current time, otherwise vest only up to the start of the next schedule.
            uint256 issuanceInterval_ = (isScheduleActive ? timestamp_ : nextSchedule_.startingTime) - lastIssued_;

            issuableAmount_ += currentSchedule_.issuanceRate * issuanceInterval_ / PRECISION;

            // End the issuance here if the current schedule is still active.
            if (isScheduleActive) break;

            // Otherwise repeat the entire process for the next schedule.
            lastIssued_     = nextSchedule_.startingTime;
            lastScheduleId_ = currentSchedule_.nextScheduleId;
        }
    }

    // Issues tokens from the time of the last issuance up until the current time.
    // The tokens are issued separately for each schedule according to their issuance rates.
    // TODO: Should this function be publicly available or permissioned?
    // TODO: Should we pass in a timestamp parameter so only tokens up to that point are issued?
    function issue() external onlyGovernor returns (uint256 tokensIssued_, uint256 lastScheduleId_) {
        ( tokensIssued_, lastScheduleId_ ) = issuableAt(block.timestamp);

        lastIssued     = block.timestamp;
        lastScheduleId = lastScheduleId_;

        IERC20Like(token).mint(IGlobalsLike(globals).mapleTreasury(), tokensIssued_);
    }

    // Sets a new schedule some time in the future (can't schedule retroactively).
    // Can be called on a yearly basis to "compound" the issuance rate or update it on demand via governance.
    // Can also be used to delete the schedule by setting the issuance rate to zero.
    // TODO: Should we set limits (maximum) to the issuance rate? Huge values could cause irreparable overflows.
    // TODO: Should we automatically call `issue()` whenever we add a new schedule?
    // TODO: Should scheduling the same issuance rate as all adjacent schedules cause all of the schedules to be merged into one?
    function schedule(uint256 startingTime_, uint256 issuanceRate_) external onlyGovernor {
        require(startingTime_ >= block.timestamp, "IM:S:OUT_OF_DATE");

        ( uint256 scheduleId_, Schedule memory schedule_ ) = _findInsertionPoint(startingTime_);

        // If the schedule already exists then replace it.
        if (startingTime_ == schedule_.startingTime) {
            schedules[scheduleId_].issuanceRate = issuanceRate_;
        }

        // Otherwise create a new schedule and insert it afterwards.
        else {
            uint256 newScheduleId_ = schedules[scheduleId_].nextScheduleId = ++scheduleCount;
            schedules[newScheduleId_] = Schedule(startingTime_, schedule_.nextScheduleId, issuanceRate_);
        }
    }

    /**************************************************************************************************************************************/
    /*** Internal Functions                                                                                                             ***/
    /**************************************************************************************************************************************/

    // Searches schedules from start to end to find where the new schedule should be inserted.
    function _findInsertionPoint(uint256 startingTime_) internal view returns (uint256 scheduleId_, Schedule memory schedule_) {
        schedule_ = schedules[scheduleId_];

        while (true) {
            Schedule memory nextSchedule_ = schedules[schedule_.nextScheduleId];

            bool foundExistingSchedule  = schedule_.startingTime == startingTime_;
            bool foundPrecedingSchedule = schedule_.nextScheduleId == 0 || startingTime_ < nextSchedule_.startingTime;

            if (foundExistingSchedule || foundPrecedingSchedule) break;

            scheduleId_ = schedule_.nextScheduleId;
            schedule_   = nextSchedule_;
        }
    }

}
