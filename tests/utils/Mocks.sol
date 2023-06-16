// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

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
