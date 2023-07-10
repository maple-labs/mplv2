// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

contract GlobalsHelper {

    address public governor;
    address public mapleTreasury;

    bool internal _isScheduled;

    function isValidScheduledCall(address, address, bytes32, bytes calldata) external view returns (bool isValidScheduledCall_) {
        return true;
    }

    function unscheduleCall(address, bytes32, bytes calldata) external { }

}
