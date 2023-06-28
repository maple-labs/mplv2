// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

import { TestBase } from "./utils/TestBase.sol";

import { InflationModule } from "../contracts/InflationModuleV2.sol";

import { MockGlobals, MockToken } from "./utils/Mocks.sol";

// TODO: Add fuzz tests.

contract InflationModuleTestBase is TestBase {

    address governor = makeAddr("governor");
    address treasury = makeAddr("treasury");

    uint256 start = block.timestamp;

    MockGlobals     globals;
    MockToken       token;
    InflationModule module;

    function setUp() public virtual {
        globals = new MockGlobals();
        token   = new MockToken();

        globals.__setGovernor(governor);
        globals.__setMapleTreasury(treasury);

        module = new InflationModule(address(globals), address(token));

        vm.warp(start);
    }

    function assertSchedule(uint256 scheduleId, uint256 startingTime, uint256 nextScheduleId, uint256 issuanceRate) internal {
        ( uint256 startingTime_, uint256 nextScheduleId_, uint256 issuanceRate_ ) = module.schedules(scheduleId);

        assertEq(startingTime_,   startingTime,   "startingTime");
        assertEq(nextScheduleId_, nextScheduleId, "nextScheduleId");
        assertEq(issuanceRate_,   issuanceRate,   "issuanceRate");
    }

}

contract ConstructorTests is InflationModuleTestBase {

    function test_inflationModule_constructor() external {
        assertEq(module.PRECISION(), 1e30);

        assertEq(module.globals(), address(globals));
        assertEq(module.token(),   address(token));

        assertEq(module.lastIssued(),     0);
        assertEq(module.lastScheduleId(), 0);
        assertEq(module.scheduleCount(),  1);

        assertSchedule(0, 0, 0, 0);
    }

}

contract IssuableAtTests is InflationModuleTestBase {

    function test_issuableAt_outOfDate() external {
        // TODO
    }

    function test_issuableAt_nothingIssued() external {
        // TODO
    }

    function test_issuableAt_oneSchedule_fromStart_oneDayAhead() external {
        // TODO
    }

    function test_issuableAt_oneSchedule_fromStart_toCurrentTime() external {
        // TODO
    }

    function test_issuableAt_oneSchedule_afterIssuance_oneDayHead() external {
        // TODO
    }

    function test_issuableAt_oneSchedule_afterIssuance_toCurrentTime() external {
        // TODO
    }

    function test_issuableAt_twoSchedules_fromStart_beforeFirstSchedule() external {
        // TODO
    }

    function test_issuableAt_twoSchedules_fromStart_beforeSecondSchedule() external {
        // TODO
    }

    function test_issuableAt_twoSchedules_fromStart_afterSecondSchedule() external {
        // TODO
    }



}

contract IssueTests is InflationModuleTestBase { }

contract ScheduleTests is InflationModuleTestBase {

    function setUp() public override {
        super.setUp();

        vm.startPrank(governor);
    }

    function test_schedule_notGovernor() external {
        vm.stopPrank();
        vm.expectRevert("IM:NOT_GOVERNOR");
        module.schedule(start, 1e30);
    }

    function test_schedule_firstSchedule_outOfDate() external {
        vm.expectRevert("IM:S:OUT_OF_DATE");
        module.schedule(start - 1 seconds, 1e30);

        module.schedule(start, 1e30);
    }

    function test_schedule_secondSchedule_outOfDate() external {
        module.schedule(start, 1e30);

        vm.warp(start + 10 days);
        vm.expectRevert("IM:S:OUT_OF_DATE");
        module.schedule(start + 10 days - 1 seconds, 1e30);

        module.schedule(start + 10 days, 1e30);
    }

    function test_schedule_firstSchedule_success() external {
        module.schedule(start, 1e30);

        assertSchedule(0, 0,     1, 0);
        assertSchedule(1, start, 0, 1e30);

        assertEq(module.scheduleCount(), 2);
    }

    function test_schedule_twoSchedules_success() external {
        module.schedule(start + 10 days,  1e30);
        module.schedule(start + 175 days, 1.1e30);

        assertSchedule(0, 0,                1, 0);
        assertSchedule(1, start + 10 days,  2, 1e30);
        assertSchedule(2, start + 175 days, 0, 1.1e30);

        assertEq(module.scheduleCount(), 3);
    }

    function test_schedule_threeSchedules_withInsert() external {
        module.schedule(start + 50 days,  1e30);
        module.schedule(start + 100 days, 1.1e30);
        module.schedule(start + 75 days,  1.05e30);

        assertSchedule(0, 0,                1, 0);
        assertSchedule(1, start + 50 days,  3, 1e30);
        assertSchedule(2, start + 100 days, 0, 1.1e30);
        assertSchedule(3, start + 75 days,  2, 1.05e30);

        assertEq(module.scheduleCount(), 4);
    }

    function test_schedule_threeSchedules_withInsertAndUpdate() external {
        module.schedule(start + 50 days,  1e30);
        module.schedule(start + 100 days, 1.1e30);
        module.schedule(start + 75 days,  1.05e30);
        module.schedule(start + 50 days,  0.98e30);

        assertSchedule(0, 0,                1, 0);
        assertSchedule(1, start + 50 days,  3, 0.98e30);
        assertSchedule(2, start + 100 days, 0, 1.1e30);
        assertSchedule(3, start + 75 days,  2, 1.05e30);

        assertEq(module.scheduleCount(), 4);
    }

}






















// contract GetAccruedAmountTests is InflationModuleTestBase {

//     function test_interestFor_fixtures() external {
//         _assertAmount(0, 0.05e6, 365 days, 0);

//         _assertAmount(10_000_000e6, 0.05e6, 365 days * 4, 2_000_000e6);
//         _assertAmount(10_000_000e6, 0.05e6, 365 days * 2, 1_000_000e6);
//         _assertAmount(10_000_000e6, 0.05e6, 365 days,     500_000e6);
//         _assertAmount(10_000_000e6, 0.05e6, 365 days / 2, 250_000e6);
//         _assertAmount(10_000_000e6, 0.05e6, 365 days / 4, 125_000e6);

//         _assertAmount(1_234_567e6, 0.05e6, 365 days,     61_728.350000e6);
//         _assertAmount(1_234_567e6, 0.05e6, 365 days / 6, 10_288.058333e6);
//     }

//     function _assertAmount(uint256 supply, uint256 rate, uint256 interval, uint256 expected) internal {
//         uint256 actual = inflationModule.__interestFor(interval, supply, rate);
//         assertEq(actual, expected);
//     }

// }

// contract DueTokensAtTests is InflationModuleTestBase {

//     uint256 year          = 365 days;
//     uint256 currentSupply = 10_000_000e18;

//     function setUp() public override {
//         super.setUp();

//         token.__setTotalSupply(currentSupply);

//         vm.prank(governor);
//         inflationModule.start();

//         start = block.timestamp;
//     }

//     function test_dueTokensAt_fixtures() external {

//         _assertDueTokensAt({
//             timestamp:            start + year / 2,  // 6 months
//             expectedAmount:       250_000e18,
//             expectedSupply:       currentSupply,
//             expectedPeriodStart:  start
//         });

//         _assertDueTokensAt({
//             timestamp:            start + year,  // Full Period
//             expectedAmount:       500_000e18,
//             expectedSupply:       currentSupply,
//             expectedPeriodStart:  start
//         });

//         _assertDueTokensAt({
//             timestamp:            start + year + year / 2,  // 1.5 years
//             expectedAmount:       500_000e18 + 262_500e18,
//             expectedSupply:       currentSupply + 500_000e18,
//             expectedPeriodStart:  start + year
//         });

//         _assertDueTokensAt({
//             timestamp:            start + (3 * year),                       // 3 years from now
//             expectedAmount:       500_000e18 + 525_000e18 + 551_250e18,     // 500k from 1st year + 525k from 2nd year + 551.250k from 3rd
//             expectedSupply:       currentSupply + 500_000e18 + 525_000e18 + 551_250e18,
//             expectedPeriodStart:  start + (3 * year)
//         });

//     }

//     function _assertDueTokensAt(uint256 timestamp, uint256 expectedAmount, uint256 expectedSupply, uint256 expectedPeriodStart) internal {
//         ( uint256 amount, uint256 supply, uint256 periodStart ) = inflationModule.__dueTokensAt(timestamp);

//         assertEq(amount,      expectedAmount);
//         assertEq(supply,      expectedSupply);
//         assertEq(periodStart, expectedPeriodStart);
//     }

// }

// contract InflationModulesTests is InflationModuleTestBase {

//     uint256 currentSupply = 10_000_000e18;

//     function test_start_notGovernor() external {
//         vm.expectRevert("IM:S:NOT_GOVERNOR");
//         inflationModule.start();
//     }

//     function test_start_success() external {
//         token.__setTotalSupply(currentSupply);

//         vm.prank(governor);
//         inflationModule.start();

//         assertEq(inflationModule.periodStart(), block.timestamp);
//         assertEq(inflationModule.lastUpdated(), block.timestamp);
//         assertEq(inflationModule.supply(),      currentSupply);
//     }

//     function test_setRate_notGovernor() external {
//         vm.expectRevert("IM:SR:NOT_GOVERNOR");
//         inflationModule.setRate(0.09e6);
//     }

//     function test_serRate_beforeStart() external {
//         vm.prank(governor);
//         inflationModule.setRate(0.09e6);

//         assertEq(inflationModule.rate(), 0.09e6);

//         // Should not have updated periodStart
//         assertEq(inflationModule.periodStart(), 0);
//         assertEq(inflationModule.lastUpdated(), 0);
//     }

//     function test_setRate_afterStart() external {
//         token.__setTotalSupply(currentSupply);

//         vm.prank(governor);
//         inflationModule.start();
//         start = block.timestamp;

//         vm.warp(start + (365 days / 2));

//         token.__expectCall();
//         token.mint(treasury, 250_000e18);

//         vm.prank(governor);
//         inflationModule.setRate(0.09e6);

//         assertEq(inflationModule.rate(),        0.09e6);
//         assertEq(inflationModule.periodStart(), start);
//         assertEq(inflationModule.lastUpdated(), block.timestamp);
//     }

//     function test_claim_notStarted() external {
//         vm.expectRevert("IM:C:NOT_STARTED");
//         inflationModule.claim();
//     }

//     function test_claim_withinPeriod() external {
//         token.__setTotalSupply(currentSupply);

//         vm.prank(governor);
//         inflationModule.start();
//         start = block.timestamp;

//         vm.warp(start + (365 days / 2));

//         token.__expectCall();
//         token.mint(treasury, 250_000e18);

//         inflationModule.claim();

//         assertEq(inflationModule.periodStart(), start);
//         assertEq(inflationModule.lastUpdated(), block.timestamp);
//         assertEq(inflationModule.supply(),      currentSupply);
//     }

//     function test_claim_periodCrossover_noSupplyChange() external {
//         token.__setTotalSupply(currentSupply);

//         vm.prank(governor);
//         inflationModule.start();
//         start = block.timestamp;

//         vm.warp(start + 365 days + (365 days / 10));

//         token.__expectCall();
//         token.mint(treasury, 500_000e18 + 52_500e18);

//         inflationModule.claim();

//         assertEq(inflationModule.periodStart(), start + 365 days);
//         assertEq(inflationModule.lastUpdated(), block.timestamp);
//         assertEq(inflationModule.supply(),      currentSupply + 500_000e18);
//     }

//     function test_claim_periodCrossover_withSupplyChange() external {
//         token.__setTotalSupply(currentSupply);

//         vm.prank(governor);
//         inflationModule.start();
//         start = block.timestamp;

//         vm.warp(start + 365 days + (365 days / 10));

//         token.__setTotalSupply(4_500_000e18);

//         token.__expectCall();
//         token.mint(treasury, 500_000e18 + 25_000e18);

//         inflationModule.claim();

//         assertEq(inflationModule.periodStart(), start + 365 days);
//         assertEq(inflationModule.lastUpdated(), block.timestamp);
//         assertEq(inflationModule.supply(),      5_000_000e18);

//     }
// }
