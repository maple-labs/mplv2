// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

import { IERC20Like, IGlobalsLike } from "./interfaces/Interfaces.sol";

import { console } from "../modules/forge-std/src/console.sol";

// TODO: Add interface (with struct?), events, NatSpec.
// TODO: Define which state variables should be publicly exposed.

contract InflationModule {

    // TODO: Add struct optimization?
    // TODO: If struct optimization is not relevant, should order of variables be alphabetical or whatever is most intuitive?
    struct Schedule {
        uint256 startingTime;    // Defines when token issuance begins and at which rate tokens will be issued.
        uint256 nextScheduleId;  // Issuance takes effect from the starting time of the schedule up until the next one (if it exists).
        uint256 issuanceRate;    // Defines the rate at which tokens will be issued (can be zero to stop issuance).
    }

    uint256 public constant PRECISION = 1e30;  // Precision of the issuance rate.

    address public globals;  // Address of the MapleGlobals contract.
    address public token;    // Address of the MapleToken contract.

    uint256 public lastIssued;      // Stores the timestamp when tokens were last issued.
    uint256 public lastScheduleId;  // Stores the identifier of the schedule during which tokens were last issued.
    uint256 public scheduleCount;   // Stores the number of schedules created so far.

    // TODO: Look into if linked list optimizations are needed: not adding schedules if issuance rate is same, removing duplicates, etc.
    mapping(uint256 => Schedule) public schedules;  // Maps identifiers to schedules (effectively an implementation of a linked list).

    modifier onlyGovernor {
        require(msg.sender == IGlobalsLike(globals).governor(), "IM:NOT_GOVERNOR");

        _;
    }

    // TODO: Should this module be a proxy instead?
    constructor(address globals_, address token_) {
        globals = globals_;
        token   = token_;

        // The first schedule is the one at index 0, and all of it's values are zero.
        // TODO: Should the starting time of the first schedule be `0` or `block.timestamp`?
        // TODO: Should the schedules the first schedule have an index of `0` or `1`?
        scheduleCount = 1;
    }

    /**************************************************************************************************************************************/
    /*** External Functions                                                                                                             ***/
    /**************************************************************************************************************************************/

    // TODO: Add invariant test that checks the current amount of issuable tokens is not beyond a certain limit.
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
    function issue() external returns (uint256 tokensIssued_, uint256 lastScheduleId_) {
        ( tokensIssued_, lastScheduleId_ ) = issuableAt(block.timestamp);

        lastIssued     = block.timestamp;
        lastScheduleId = lastScheduleId_;

        IERC20Like(token).mint(IGlobalsLike(globals).mapleTreasury(), tokensIssued_);
    }

    // Sets a new schedule some time in the future (can't schedule retroactively).
    // Can be called on a yearly basis to "compound" the issuance rate or update it on demand via governance.
    // Can also be used to delete the schedule by setting the issuance rate to zero.
    // TODO: Should we set limits (maximum) to the issuance rate? Huge values could cause irreparable overflows.
    // TODO: Should setting the issuance rate delete the schedule entirely?
    // TODO: Should we automatically call `issue()` whenever we add a new schedule?
    function schedule(uint256 startingTime_, uint256 issuanceRate_) external onlyGovernor {
        require(startingTime_ >= block.timestamp, "IM:S:OUT_OF_DATE");

        bool updateSchedule_;
        bool createSchedule_;

        uint256 scheduleId_;

        Schedule memory schedule_;

        while (!updateSchedule_ && !createSchedule_) {
            scheduleId_ = schedule_.nextScheduleId;
            schedule_   = schedules[scheduleId_];

            updateSchedule_ = startingTime_ == schedule_.startingTime;
            createSchedule_ = schedule_.nextScheduleId == 0 || startingTime_ < schedules[schedule_.nextScheduleId].startingTime;
        }

        // Just update the issuance rate if the schedule already exists.
        if (updateSchedule_) {
            schedules[scheduleId_].issuanceRate = issuanceRate_;
        }

        // If there is no next schedule or the new one begins before the next one, add a new schedule.
        else {
            uint256 newScheduleId_ = scheduleCount++;

            schedules[scheduleId_].nextScheduleId = newScheduleId_;
            schedules[newScheduleId_] = Schedule({
                startingTime:   startingTime_,
                issuanceRate:   issuanceRate_,
                nextScheduleId: schedule_.nextScheduleId == 0 ? 0 : schedule_.nextScheduleId
            });
        }
    }

}
