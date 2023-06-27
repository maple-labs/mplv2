// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

import { IERC20Like, IGlobalsLike } from "./interfaces/Interfaces.sol";

contract IssuanceModule {

    struct Schedule {
        uint256 startingTime;    // Defines when token issuance begins and at which rate tokens will be issued.
        uint256 issuanceRate;    // Defines the rate at which tokens will be issued (can be zero to stop issuance).
        uint256 nextScheduleId;  // Issuance takes effect from the starting time of the schedule up until the next one (if it exists).
    }

    uint256 constant PRECISION = 1e30;  // Precision of the issuance rate.

    address globals;  // Address of the MapleGlobals contract.
    address token;    // Address of the MapleToken contract.

    uint256 lastIssued;      // Stores the timestamp when tokens were last issued.
    uint256 lastScheduleId;  // Stores the identifier of the schedule during which tokens were last issued.
    uint256 scheduleCount;   // Stores the number of schedules created so far.

    mapping(uint256 => Schedule) schedules;  // Maps identifiers to schedules (effectively an implementation of a linked list).

    modifier onlyGovernor {
        require(msg.sender == IGlobalsLike(globals).governor(), "IM:NOT_GOVERNOR");

        _;
    }

    constructor(address globals_, address token_) {
        globals = globals_;
        token   = token_;

        // The first schedule is the one at index 0, and all of it's values are zero.
        scheduleCount = 1;
    }

    /**************************************************************************************************************************************/
    /*** External Functions                                                                                                             ***/
    /**************************************************************************************************************************************/

    // Sets a new schedule some time in the future (can't schedule retroactively).
    // Can be called on a yearly basis to "compound" the issuance rate or update it on demand via governance.
    // Can also be used to delete the schedule by setting the issuance rate to zero.
    function schedule(uint256 startingTime_, uint256 issuanceRate_) external onlyGovernor {
        require(startingTime_ >= block.timestamp, "IM:S:OUT_OF_DATE");

        uint256 scheduleId_;

        while (true) {
            Schedule memory schedule_     = schedules[scheduleId_];
            Schedule memory nextSchedule_ = schedules[schedule_.nextScheduleId];

            // Just update the issuance rate if the schedule already exists.
            if (startingTime_ == schedule_.startingTime) {
                schedules[scheduleId_].issuanceRate = issuanceRate_;
            }

            // If there is no next schedule or the new one begins before the next one, add a new schedule.
            else if (schedule_.nextScheduleId == 0 || startingTime_ < nextSchedule_.startingTime) {
                uint256 newScheduleId_ = scheduleCount++;

                schedules[scheduleId_].nextScheduleId = newScheduleId_;
                schedules[newScheduleId_] = Schedule(
                    startingTime_,
                    issuanceRate_,
                    schedule_.nextScheduleId == 0 ? 0 : schedule_.nextScheduleId
                );
            }

            scheduleId_ = schedule_.nextScheduleId;
        }
    }

    // Issues tokens from the time of the last issuance up until the current time.
    // The tokens are issued separately for each schedule according to their issuance rates.
    function issue() public returns (uint256 tokensIssued_) {
        uint256 currentScheduleId_ = lastScheduleId;
        uint256 lastIssued_        = lastIssued;

        while (true) {
            Schedule memory currentSchedule_ = schedules[currentScheduleId_];
            Schedule memory nextSchedule_    = schedules[currentSchedule_.nextScheduleId];

            // Check if the current schedule is still active.
            bool isScheduleActive = currentSchedule_.nextScheduleId == 0 ? true : block.timestamp < nextSchedule_.startingTime;

            // If it's still active vest up to the current time, otherwise vest only up to the start of the next schedule.
            uint256 issuanceInterval_ = (isScheduleActive ? block.timestamp : nextSchedule_.startingTime) - lastIssued_;

            tokensIssued_ += currentSchedule_.issuanceRate * issuanceInterval_ / PRECISION;

            // End the issuance here if the current schedule is still active.
            if (isScheduleActive) break;

            // Otherwise repeat the entire process for the next schedule.
            currentScheduleId_ = currentSchedule_.nextScheduleId;
            lastIssued_        = nextSchedule_.startingTime;
        }

        lastScheduleId = currentScheduleId_;
        lastIssued     = block.timestamp;

        IERC20Like(token).mint(IGlobalsLike(globals).mapleTreasury(), tokensIssued_);
    }

}
