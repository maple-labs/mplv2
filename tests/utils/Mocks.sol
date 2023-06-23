// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

import { Test } from "../../modules/forge-std/src/Test.sol";

contract Spied is Test {

    bool internal assertCalls;
    bool internal captureCall;

    uint256 callCount;

    bytes[] internal calls;

    modifier spied() {
        if (captureCall) {
            calls.push(msg.data);
            captureCall = false;
        } else {
            if (assertCalls) {
                assertEq(msg.data, calls[callCount++], "Unexpected call spied");
            }

            _;
        }
    }

    function __expectCall() public {
        assertCalls = true;
        captureCall = true;
    }

}

contract MockGlobals is Spied {

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

    function unscheduleCall(address, address, bytes32, bytes calldata) external spied { }

}

contract MockToken is Spied {

    uint256 public totalSupply;

    function mint(address , uint256 amount) external spied {
        // Just increase the supply
        totalSupply += amount;
    }

    function burn(address, uint256) external spied {
        // do nothing
    }

    function __setTotalSupply(uint256 totalSupply_) external {
        totalSupply = totalSupply_;
    }

}
