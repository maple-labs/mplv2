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

contract MockGlobals {
    
    address public governor;
    address public mapleTreasury;

    function __setGovernor(address governor_) external {
        governor = governor_;
    }

    function __setMapleTreasury(address mapleTreasury_) external {
        mapleTreasury = mapleTreasury_;
    }

}

contract MockToken is Spied {

    function mint(address to, uint256 amount) external spied {
        // do nothing
    }

    function burn(address from, uint256 amount) external spied {
        // do nothing
    }

}
