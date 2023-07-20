// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

import { InflationModule } from "../../contracts/InflationModule.sol";

contract InflationModuleHarness is InflationModule {

    constructor(address token) InflationModule(token) { }

    function findInsertionPoint(uint32 windowStart) external view returns (uint16 windowId) {
        windowId = super._findInsertionPoint(windowStart);
    }

}
