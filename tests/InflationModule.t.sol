// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

import { TestBase } from "./utils/TestBase.sol";

import { EmergencyModule } from "../contracts/EmergencyModule.sol";

import { MockGlobals, MockToken } from "./utils/Mocks.sol";

import { InflationModuleHarness } from "./utils/Harnesses.sol";

contract InflationModuleTestBase is TestBase {

    address governor = makeAddr("governor");
    address treasury = makeAddr("treasury");

    uint256 start;

    MockGlobals            globals;
    MockToken              token;
    InflationModuleHarness inflationModule;

    function setUp() public virtual {
        globals = new MockGlobals();
        globals.__setGovernor(governor);
        globals.__setMapleTreasury(treasury);

        token           = new MockToken();
        inflationModule = new InflationModuleHarness(address(token), address(globals), 0.05e6);
    }

}

contract GetAccruedAmountTests is InflationModuleTestBase {

    function test_interestFor_fixtures() external {
        _assertAmount(0, 0.05e6, 365 days, 0);

        _assertAmount(10_000_000e6, 0.05e6, 365 days * 4, 2_000_000e6);
        _assertAmount(10_000_000e6, 0.05e6, 365 days * 2, 1_000_000e6);
        _assertAmount(10_000_000e6, 0.05e6, 365 days,     500_000e6);
        _assertAmount(10_000_000e6, 0.05e6, 365 days / 2, 250_000e6);
        _assertAmount(10_000_000e6, 0.05e6, 365 days / 4, 125_000e6);

        _assertAmount(1_234_567e6, 0.05e6, 365 days,     61_728.350000e6);
        _assertAmount(1_234_567e6, 0.05e6, 365 days / 6, 10_288.058333e6);
    }

    function _assertAmount(uint256 supply, uint256 rate, uint256 interval, uint256 expected) internal {
        uint256 actual = inflationModule.__interestFor(interval, supply, rate);
        assertEq(actual, expected);
    }

}

contract DueTokensAtTests is InflationModuleTestBase {

    uint256 year          = 365 days;
    uint256 currentSupply = 10_000_000e18;

    function setUp() public override {
        super.setUp();

        token.__setTotalSupply(currentSupply);

        vm.prank(governor);
        inflationModule.start();

        start = block.timestamp;
    }

    function test_dueTokensAt_fixtures() external {

        _assertDueTokensAt({
            timestamp:            start + year / 2,  // 6 months
            expectedAmount:       250_000e18, 
            expectedSupply:       currentSupply, 
            expectedPeriodStart:  start
        });

        _assertDueTokensAt({
            timestamp:            start + year,  // Full Period
            expectedAmount:       500_000e18, 
            expectedSupply:       currentSupply, 
            expectedPeriodStart:  start
        });

        _assertDueTokensAt({
            timestamp:            start + year + year / 2,  // 1.5 years
            expectedAmount:       500_000e18 + 262_500e18, 
            expectedSupply:       currentSupply + 500_000e18, 
            expectedPeriodStart:  start + year
        });

        _assertDueTokensAt({
            timestamp:            start + (3 * year),                       // 3 years from now
            expectedAmount:       500_000e18 + 525_000e18 + 551_250e18,     // 500k from 1st year + 525k from 2nd year + 551.250k from 3rd
            expectedSupply:       currentSupply + 500_000e18 + 525_000e18 + 551_250e18, 
            expectedPeriodStart:  start + (3 * year) 
        });

    }

    function _assertDueTokensAt(uint256 timestamp, uint256 expectedAmount, uint256 expectedSupply, uint256 expectedPeriodStart) internal {
        ( uint256 amount, uint256 supply, uint256 periodStart ) = inflationModule.__dueTokensAt(timestamp);

        assertEq(amount,      expectedAmount);
        assertEq(supply,      expectedSupply);
        assertEq(periodStart, expectedPeriodStart);
    }
    
}

contract InflationModulesTests is InflationModuleTestBase {

    uint256 currentSupply = 10_000_000e18;
    
    function test_start_notGovernor() external {
        vm.expectRevert("IM:S:NOT_GOVERNOR");
        inflationModule.start();
    }

    function test_start_success() external {
        token.__setTotalSupply(currentSupply);

        vm.prank(governor);
        inflationModule.start();

        assertEq(inflationModule.periodStart(), block.timestamp);
        assertEq(inflationModule.lastUpdated(), block.timestamp); 
        assertEq(inflationModule.supply(),      currentSupply);
    }

    function test_setRate_notGovernor() external {
        vm.expectRevert("IM:SR:NOT_GOVERNOR");
        inflationModule.setRate(0.09e6);
    }

    function test_serRate_beforeStart() external {
        vm.prank(governor);
        inflationModule.setRate(0.09e6);

        assertEq(inflationModule.rate(), 0.09e6);

        // Should not have updated periodStart
        assertEq(inflationModule.periodStart(), 0);
        assertEq(inflationModule.lastUpdated(), 0); 
    }

    function test_setRate_afterStart() external {
        token.__setTotalSupply(currentSupply);

        vm.prank(governor);
        inflationModule.start();
        start = block.timestamp;

        vm.warp(start + (365 days / 2));

        token.__expectCall();
        token.mint(treasury, 250_000e18);

        vm.prank(governor);
        inflationModule.setRate(0.09e6);

        assertEq(inflationModule.rate(),        0.09e6);
        assertEq(inflationModule.periodStart(), start);
        assertEq(inflationModule.lastUpdated(), block.timestamp); 
    }

    function test_claim_notStarted() external {
        vm.expectRevert("IM:C:NOT_STARTED");
        inflationModule.claim();
    }

    function test_claim_withinPeriod() external {
        token.__setTotalSupply(currentSupply);

        vm.prank(governor);
        inflationModule.start();
        start = block.timestamp;

        vm.warp(start + (365 days / 2));

        token.__expectCall();
        token.mint(treasury, 250_000e18);

        inflationModule.claim();

        assertEq(inflationModule.periodStart(), start);
        assertEq(inflationModule.lastUpdated(), block.timestamp); 
        assertEq(inflationModule.supply(),      currentSupply);
    }

    function test_claim_periodCrossover_noSupplyChange() external {
        token.__setTotalSupply(currentSupply);

        vm.prank(governor);
        inflationModule.start();
        start = block.timestamp;

        vm.warp(start + 365 days + (365 days / 10));

        token.__expectCall();
        token.mint(treasury, 500_000e18 + 52_500e18);

        inflationModule.claim();

        assertEq(inflationModule.periodStart(), start + 365 days);
        assertEq(inflationModule.lastUpdated(), block.timestamp); 
        assertEq(inflationModule.supply(),      currentSupply + 500_000e18);
    }

    function test_claim_periodCrossover_withSupplyChange() external {
        token.__setTotalSupply(currentSupply);

        vm.prank(governor);
        inflationModule.start();
        start = block.timestamp;

        vm.warp(start + 365 days + (365 days / 10));
 
        token.__setTotalSupply(4_500_000e18);

        token.__expectCall();
        token.mint(treasury, 500_000e18 + 25_000e18);

        inflationModule.claim();

        assertEq(inflationModule.periodStart(), start + 365 days);
        assertEq(inflationModule.lastUpdated(), block.timestamp); 
        assertEq(inflationModule.supply(),      5_000_000e18);

    }
}
