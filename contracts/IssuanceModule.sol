// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

import { IERC20Like, IGlobalsLike } from "./interfaces/Interfaces.sol";

contract IssuanceModule {

    struct Schedule {
        uint256 issuanceRate;
        uint256 startingTime;
    }

    // Precision of the issuance rate.
    uint256 constant PRECISION = 1e30;

    address globals;
    address token;

    // Indicates the first schedule to process during the next issuance.
    uint256 lastIssued;

    // Defines when issuance schedules begin and at which rate tokens will be issued during the schedule.
    // Issuance rates take effect from the start of the schedule up until the next one (or indefinitely if it's the last schedule).
    // TODO: Should be an implementation of a linked list to allow for updates of any pending schedule (not only the last one).
    Schedule[] schedules;

    modifier onlyGovernor {
        require(msg.sender == IGlobalsLike(globals).governor(), "IM:NOT_GOVERNOR");

        _;
    }

    constructor(address globals_, address token_) {
        globals = globals_;
        token   = token_;

        // Specifies that no tokens should be issued.
        schedules.push(Schedule(0, 0));
    }

    // Schedules issuance of tokens after a specific timestamp is reached.
    // Issuance can only be scheduled from the current timestamp or some time in the future (can't issue tokens retroactively).
    // Can be used to delete the schedule by setting the issuance rate to zero.
    // This could be called on a yearly basis to "compound" the issuance rate or update it through some governance process.
    function schedule(uint256 startingTime_, uint256 issuanceRate_) external onlyGovernor {
        require(startingTime_ >= block.timestamp, "IM:S:OUTDATED");

        // TODO: Find the point in the linked list when the schedule should be inserted.
        // TODO: Update the issuance rate if the schedule already exists, or delete it if the issuance rate is zero.
    }

    function issue() external {
        uint256 tokensToIssue_ = 0;

        // TODO: Start from the timestamp of the last issuance and calculate how many tokens to mint up until the current timestamp.

        IERC20Like(token).mint(IGlobalsLike(globals).mapleTreasury(), tokensToIssue_);

        lastIssued = block.timestamp;
    }

}
