// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

contract MockGlobals {

    address public governor;
    address public mapleTreasury;

    bool internal isScheduled;

    function __setGovernor(address governor_) external {
        governor = governor_;
    }

    function __setMapleTreasury(address mapleTreasury_) external {
        mapleTreasury = mapleTreasury_;
    }

    function __setIsValidScheduledCall(bool isValidScheduledCall_) external {
        isScheduled = isValidScheduledCall_;
    }

    function isValidScheduledCall(address, address, bytes32, bytes calldata) external view returns (bool isValidScheduledCall_) {
        isValidScheduledCall_ = isScheduled;
    }

    function unscheduleCall(address, address, bytes32, bytes calldata) external { }

}
