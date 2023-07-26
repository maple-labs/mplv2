// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

import { InflationModule } from "../../contracts/InflationModule.sol";

contract InflationModuleHarness is InflationModule {

    constructor(address token_) InflationModule(token_) { }

    function findInsertionPoint(uint32 windowStart) external view returns (uint16 windowId) {
        windowId = super._findInsertionPoint(windowStart);
    }

}
