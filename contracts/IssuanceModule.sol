// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

import { IERC20Like, IGlobalsLike } from "./interfaces/Interfaces.sol";

contract IssuanceModule {

    struct Schedule {
        uint256 issuanceRate;    // Defines the rate at which tokens will be issued (can be zero to stop issuance).
        uint256 nextScheduleId;  // Issuance takes effect from the starting time of the schedule up until the next one (if it exists).
        uint256 startingTime;    // Defines when token issuance begins and at which rate tokens will be issued.
    }

    uint256 constant PRECISION = 1e30;  // Precision of the issuance rate.

    address globals;  // Address of the MapleGlobals contract.
    address token;    // Address of the MapleToken contract.

    uint256 lastIssued;      // Stores the timestamp when tokens were last issued.
    uint256 lastScheduleId;  // Stores the identifier of the schedule during which tokens were last issued.

    mapping(uint256 => Schedule) schedules;  // Maps identifiers to schedules (effectively an implementation of a linked list).

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

    // Issuance can only be scheduled from the current time or some time in the future (can't issue tokens retroactively).
    // This could be called on a yearly basis to "compound" the issuance rate or update it on demand via governance.
    // Can also be used to delete the schedule by setting the issuance rate to zero.
    function schedule(uint256 startingTime_, uint256 issuanceRate_) external onlyGovernor {
        require(block.timestamp <= startingTime_, "IM:S:OUTDATED");

        // TODO: Find the point in the linked list when the schedule should be inserted.
        // TODO: Update the issuance rate if the schedule already exists, or delete it if the issuance rate is zero.
    }

    // Issues tokens from the time of the last issuance up until the current time.
    // The tokens are issued separately for each schedule according to their issuance rates.
    function issue() external returns (uint256 tokensIssued_) {
        uint256 currentScheduleId_ = lastScheduleId;
        uint256 lastIssued_        = lastIssued;

        while (true) {
            Schedule memory currentSchedule_ = schedules[currentScheduleId_];
            Schedule memory nextSchedule_    = schedules[currentSchedule_.nextScheduleId];

            bool isScheduleActive = currentSchedule_.nextScheduleId == 0 ? true : block.timestamp < nextSchedule_.startingTime;
            uint256 issuanceInterval_ = (isScheduleActive ? block.timestamp : nextSchedule_.startingTime) - lastIssued_;

            tokensIssued_ += currentSchedule_.issuanceRate * issuanceInterval_ / PRECISION;

            if (isScheduleActive) break;

            currentScheduleId_ = currentSchedule_.nextScheduleId;
            lastIssued_        = nextSchedule_.startingTime;
        }

        lastScheduleId = currentScheduleId_;
        lastIssued     = block.timestamp;

        IERC20Like(token).mint(IGlobalsLike(globals).mapleTreasury(), tokensIssued_);
    }

}
