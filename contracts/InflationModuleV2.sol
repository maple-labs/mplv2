// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

import { IERC20Like, IGlobalsLike } from "./interfaces/Interfaces.sol";

import { console } from "../modules/forge-std/src/console.sol";

// TODO: Add interface (with struct?), events, NatSpec.
// TODO: Define which state variables should be publicly exposed.

contract InflationModule {

    // TODO: If struct optimization is not relevant, should order of variables be alphabetical or whatever is most intuitive?
    struct Schedule {
        uint16  scheduleId;      // Identifier of the schedule (stored redundantly for convenience).
        uint16  nextScheduleId;  // Identifier of the schedule that takes effect after this one (zero if there is none).
        uint32  issuanceStart;   // Timestamp that defines when the schedule will start. It lasts until the start of the next schedule.
        uint256 issuanceRate;    // Defines the rate at which tokens will be issued (zero indicates no issuance).
    }

    uint256 public constant PRECISION = 1e30;  // Precision of the issuance rate.

    address public immutable globals;  // Address of the MapleGlobals contract.
    address public immutable token;    // Address of the MapleToken contract.

    uint16 public lastScheduleId;  // Stores the identifier of the schedule during which tokens were last issued.
    uint16 public scheduleCount;   // Stores the number of schedules created so far.

    uint32 public lastIssued;  // Stores the timestamp when tokens were last issued.

    mapping(uint16 => Schedule) public schedules;  // Maps identifiers to schedules (effectively an implementation of a linked list).

    modifier onlyGovernor {
        require(msg.sender == IGlobalsLike(globals).governor(), "IM:NOT_GOVERNOR");

        _;
    }

    // TODO: Should this module be a proxy instead?
    constructor(address globals_, address token_) {
        globals = globals_;
        token   = token_;

        scheduleCount = 1;
    }

    /**************************************************************************************************************************************/
    /*** External Functions                                                                                                             ***/
    /**************************************************************************************************************************************/

    // TODO: Add invariant test that checks the current amount of issuable tokens is not beyond a certain limit.
    function issuableAt(uint32 issuanceTime_) public view returns (uint256 issuableAmount_, uint16 lastScheduleId_) {
        uint32 lastIssued_ = lastIssued;
        lastScheduleId_    = lastScheduleId;

        require(issuanceTime_ >= lastIssued_, "IM:IA:OUT_OF_DATE");

        while (true) {
            Schedule memory currentSchedule_ = schedules[lastScheduleId_];
            Schedule memory nextSchedule_    = schedules[currentSchedule_.nextScheduleId];

            // Check if the current schedule is still active.
            bool isScheduleActive = currentSchedule_.nextScheduleId == 0 ? true : issuanceTime_ < nextSchedule_.issuanceStart;

            // If it's still active vest up to the current time, otherwise vest only up to the start of the next schedule.
            uint256 issuanceInterval_ = (isScheduleActive ? issuanceTime_ : nextSchedule_.issuanceStart) - lastIssued_;

            issuableAmount_ += currentSchedule_.issuanceRate * issuanceInterval_ / PRECISION;

            // End the issuance here if the current schedule is still active.
            if (isScheduleActive) break;

            // Otherwise repeat the entire process for the next schedule.
            lastIssued_     = nextSchedule_.issuanceStart;
            lastScheduleId_ = currentSchedule_.nextScheduleId;
        }
    }

    // Issues tokens from the time of the last issuance up until the current time.
    // The tokens are issued separately for each schedule according to their issuance rates.
    function issue() external returns (uint256 tokensIssued_, uint16 lastScheduleId_) {
        ( tokensIssued_, lastScheduleId_ ) = issuableAt(uint32(block.timestamp));

        lastIssued     = uint32(block.timestamp);
        lastScheduleId = lastScheduleId_;

        IERC20Like(token).mint(IGlobalsLike(globals).mapleTreasury(), tokensIssued_);
    }

    // Sets a new schedule some time in the future (can't schedule retroactively).
    // Can be called on a yearly basis to "compound" the issuance rate or update it on demand via governance.
    // Can also be used to delete the schedule by setting the issuance rate to zero.
    // TODO: Should we set limits (maximum) to the issuance rate? Huge values could cause irreparable overflows. ACL `issue()` or max IR?
    function schedule(uint32 issuanceStart_, uint256 issuanceRate_) external onlyGovernor {
        require(issuanceStart_ >= block.timestamp, "IM:S:OUT_OF_DATE");

        ( Schedule memory schedule_ ) = _findInsertionPoint(issuanceStart_);

        // If the schedule already exists then replace it.
        if (issuanceStart_ == schedule_.issuanceStart) {
            schedules[schedule_.scheduleId].issuanceRate = issuanceRate_;
        }

        // Otherwise create a new schedule and insert it.
        else {
            uint16 newScheduleId_ = schedules[schedule_.scheduleId].nextScheduleId = scheduleCount++;
            schedules[newScheduleId_] = Schedule(newScheduleId_, schedule_.nextScheduleId, issuanceStart_, issuanceRate_);
        }
    }

    /**************************************************************************************************************************************/
    /*** Internal Functions                                                                                                             ***/
    /**************************************************************************************************************************************/

    // Searches schedules from start to end to find where the new schedule should be inserted.
    function _findInsertionPoint(uint256 issuanceStart_) internal view returns (Schedule memory schedule_) {
        schedule_ = schedules[0];

        while (true) {
            Schedule memory nextSchedule_ = schedules[schedule_.nextScheduleId];

            if (schedule_.nextScheduleId == 0 || issuanceStart_ <= nextSchedule_.issuanceStart) break;

            schedule_ = nextSchedule_;
        }
    }

}
