// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

import { TestBase } from "./utils/TestBase.sol";

import { EmergencyModule } from "../contracts/EmergencyModule.sol";

import { MockGlobals, MockToken } from "./utils/Mocks.sol";

import { InflationModuleHarness } from "./utils/Harnesses.sol";

contract InflationModuleTestBase is TestBase {

    address governor = makeAddr("governor");
    address treasury = makeAddr("treasury");

    MockGlobals            globals;
    MockToken              token;
    InflationModuleHarness inflationModule;

    function setUp() external {
        globals = new MockGlobals();
        globals.__setGovernor(governor);
        globals.__setMapleTreasury(treasury);

        token           = new MockToken();
        inflationModule = new InflationModuleHarness(address(token), address(globals), 0.05e6);
    }

}

contract GetAccruedAmountTests is InflationModuleTestBase {

    function _assertAmount(uint256 supply, uint256 rate, uint256 interval, uint256 expected) internal {
        uint256 actual = inflationModule.__getAccruedAmount(interval, supply, rate);
        assertEq(actual, expected);
    }

    function test_getAccruedAmount_fixtures() external {
        _assertAmount(0, 0.05e6, 365 days, 0);

        _assertAmount(10_000_000e6, 0.05e6, 365 days * 4, 2_000_000e6);
        _assertAmount(10_000_000e6, 0.05e6, 365 days * 2, 1_000_000e6);
        _assertAmount(10_000_000e6, 0.05e6, 365 days,     500_000e6);
        _assertAmount(10_000_000e6, 0.05e6, 365 days / 2, 250_000e6);
        _assertAmount(10_000_000e6, 0.05e6, 365 days / 4, 125_000e6);

        _assertAmount(1_234_567e6, 0.05e6, 365 days,     61_728.350000e6);
        _assertAmount(1_234_567e6, 0.05e6, 365 days / 6, 10_288.058333e6);
    }

}
