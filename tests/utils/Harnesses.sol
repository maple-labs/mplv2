// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

import { InflationModule } from "../../contracts/InflationModule.sol";

contract InflationModuleHarness is InflationModule {

    constructor(address _token, address _globals, uint128 rate_) InflationModule(_token, _globals, rate_) {}

    function __dueTokensAt(uint256 timestamp) external view returns (uint256 amount_, uint256 newSupply_, uint256 newPeriodStart_) {
        return _dueTokensAt(timestamp);
    }

    function __interestFor(uint256 timeElapsed_, uint256 supply_, uint256 rate_) external pure returns (uint256) {
        return _interestFor(timeElapsed_, supply_, rate_);
    }
}
