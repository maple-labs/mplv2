// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

import { TestBase } from "./utils/TestBase.sol";

import { InflationModule } from "../contracts/InflationModuleV2.sol";

import { MockGlobals, MockToken } from "./utils/Mocks.sol";

contract InflationModuleTestBase is TestBase {

    address governor = makeAddr("governor");
    address treasury = makeAddr("treasury");

    uint32 start = uint32(block.timestamp);

    uint32[] windowStarts;

    uint208[] issuanceRates;

    MockGlobals globals;
    MockToken   token;

    InflationModule module;

    function setUp() public virtual {
        globals = new MockGlobals();
        token   = new MockToken();

        globals.__setGovernor(governor);
        globals.__setMapleTreasury(treasury);
        globals.__setIsValidScheduledCall(true);

        module = new InflationModule(address(globals), address(token));

        vm.startPrank(governor);
        vm.warp(start);
    }

    function assertWindow(uint16 windowId, uint16 nextWindowId, uint32 windowStart, uint208 issuanceRate) internal {
        (
            uint16  nextWindowId_,
            uint32  windowStart_,
            uint208 issuanceRate_
        ) = module.windows(windowId);

        assertEq(nextWindowId_, nextWindowId, "nextWindowId");
        assertEq(windowStart_,  windowStart,  "windowStart");
        assertEq(issuanceRate_, issuanceRate, "issuanceRate");
    }

    function expectUnscheduleCall() internal {
        globals.__expectCall();
        globals.unscheduleCall(governor, "IM:SCHEDULE", abi.encodeWithSelector(module.schedule.selector, windowStarts, issuanceRates));
    }

}

contract ConstructorTests is InflationModuleTestBase {

    function test_inflationModule_constructor() external {
        assertEq(module.globals(), address(globals));
        assertEq(module.token(),   address(token));

        assertEq(module.currentWindowId(),     0);
        assertEq(module.lastClaimed(),         0);
        assertEq(module.windowCounter(),       1);
        assertEq(module.maximumIssuanceRate(), 1e18);

        assertWindow(0, 0, 0, 0);
    }
}

contract ClaimTests is InflationModuleTestBase {

    // TODO

}

contract ClaimableTests is InflationModuleTestBase {

    // TODO

}

contract ScheduleTests is InflationModuleTestBase {

    function test_schedule_notGovernor() external {
        vm.stopPrank();
        vm.expectRevert("IM:NOT_GOVERNOR");
        module.schedule(windowStarts, issuanceRates);
    }

    function test_schedule_notScheduled() external {
        globals.__setIsValidScheduledCall(false);

        vm.expectRevert("IM:NOT_SCHEDULED");
        module.schedule(windowStarts, issuanceRates);
    }

    function test_schedule_noArrays() external {
        vm.expectRevert("IM:VW:EMPTY_ARRAY");
        module.schedule(windowStarts, issuanceRates);
    }

    function test_schedule_noWindowStarts() external {
        issuanceRates.push(1e18);

        vm.expectRevert("IM:VW:EMPTY_ARRAY");
        module.schedule(windowStarts, issuanceRates);
    }

    function test_schedule_noIssuanceRates() external {
        windowStarts.push(start);

        vm.expectRevert("IM:VW:EMPTY_ARRAY");
        module.schedule(windowStarts, issuanceRates);
    }

    function test_schedule_lengthMismatch() external {
        windowStarts.push(start);
        windowStarts.push(start + 10 days);

        issuanceRates.push(1e18);

        vm.expectRevert("IM:VW:LENGTH_MISMATCH");
        module.schedule(windowStarts, issuanceRates);
    }

    function test_schedule_outOfDate() external {
        windowStarts.push(start - 1 seconds);
        issuanceRates.push(1e18);

        vm.expectRevert("IM:VW:OUT_OF_DATE");
        module.schedule(windowStarts, issuanceRates);
    }

    function test_schedule_outOfOrder() external {
        windowStarts.push(start + 100 days);
        windowStarts.push(start + 10 days);

        issuanceRates.push(0.95e18);
        issuanceRates.push(1e18);

        vm.expectRevert("IM:VW:OUT_OF_ORDER");
        module.schedule(windowStarts, issuanceRates);
    }

    function test_schedule_outOfBounds() external {
        windowStarts.push(start + 10 days);
        issuanceRates.push(1e18 + 1);

        vm.expectRevert("IM:VW:OUT_OF_BOUNDS");
        module.schedule(windowStarts, issuanceRates);
    }

    function test_schedule_basic() external {
        windowStarts.push(start + 10 days);
        issuanceRates.push(0.9e18);

        expectUnscheduleCall();
        module.schedule(windowStarts, issuanceRates);

        assertEq(module.windowCounter(), 2);

        assertWindow(0, 1, 0,               0);
        assertWindow(1, 0, start + 10 days, 0.9e18);
    }

    function test_schedule_simultaneously() external {
        windowStarts.push(start + 10 days);
        windowStarts.push(start + 100 days);

        issuanceRates.push(0.9e18);
        issuanceRates.push(0.95e18);

        expectUnscheduleCall();
        module.schedule(windowStarts, issuanceRates);

        assertEq(module.windowCounter(), 3);

        assertWindow(0, 1, 0,                0);
        assertWindow(1, 2, start + 10 days,  0.9e18);
        assertWindow(2, 0, start + 100 days, 0.95e18);
    }

    function test_schedule_sequentially() external {
        windowStarts.push(start + 10 days);
        issuanceRates.push(0.9e18);

        expectUnscheduleCall();
        module.schedule(windowStarts, issuanceRates);

        windowStarts[0] = start + 100 days;
        issuanceRates[0] = 0.95e18;

        expectUnscheduleCall();
        module.schedule(windowStarts, issuanceRates);

        assertEq(module.windowCounter(), 3);

        assertWindow(0, 1, 0,                0);
        assertWindow(1, 2, start + 10 days,  0.9e18);
        assertWindow(2, 0, start + 100 days, 0.95e18);
    }

    function test_schedule_sequentiallyWithWarp() external {
        windowStarts.push(start + 10 days);
        issuanceRates.push(0.9e18);

        expectUnscheduleCall();
        vm.warp(start + 5 days);
        module.schedule(windowStarts, issuanceRates);

        windowStarts[0] = start + 100 days;
        issuanceRates[0] = 0.95e18;

        expectUnscheduleCall();
        vm.warp(start + 95 days);
        module.schedule(windowStarts, issuanceRates);

        assertEq(module.windowCounter(), 3);

        assertWindow(0, 1, 0,                0);
        assertWindow(1, 2, start + 10 days,  0.9e18);
        assertWindow(2, 0, start + 100 days, 0.95e18);
    }

    function test_schedule_append() external {
        windowStarts.push(start + 10 days);
        windowStarts.push(start + 100 days);

        issuanceRates.push(0.9e18);
        issuanceRates.push(0.95e18);

        expectUnscheduleCall();
        module.schedule(windowStarts, issuanceRates);

        windowStarts[0] = start + 150 days;
        windowStarts[1] = start + 200 days;

        issuanceRates[0] = 0.96e18;
        issuanceRates[1] = 0.99e18;

        expectUnscheduleCall();
        module.schedule(windowStarts, issuanceRates);

        assertEq(module.windowCounter(), 5);

        assertWindow(0, 1, 0,                0);
        assertWindow(1, 2, start + 10 days,  0.9e18);
        assertWindow(2, 3, start + 100 days, 0.95e18);
        assertWindow(3, 4, start + 150 days, 0.96e18);
        assertWindow(4, 0, start + 200 days, 0.99e18);
    }

    function test_schedule_insert() external {
        windowStarts.push(start + 10 days);
        windowStarts.push(start + 100 days);

        issuanceRates.push(0.9e18);
        issuanceRates.push(0.95e18);

        expectUnscheduleCall();
        module.schedule(windowStarts, issuanceRates);

        windowStarts[0] = start + 50 days;
        windowStarts[1] = start + 120 days;

        issuanceRates[0] = 0.96e18;
        issuanceRates[1] = 0.99e18;

        expectUnscheduleCall();
        module.schedule(windowStarts, issuanceRates);

        assertEq(module.windowCounter(), 5);

        assertWindow(0, 1, 0,                0);
        assertWindow(1, 3, start + 10 days,  0.9e18);
        assertWindow(3, 4, start + 50 days,  0.96e18);
        assertWindow(4, 0, start + 120 days, 0.99e18);
    }

}

contract SetMaximumIssuanceRateTests is InflationModuleTestBase {

    function test_setMaximumIssuanceRate_notGovernor() external {
        vm.stopPrank();
        vm.expectRevert("IM:NOT_GOVERNOR");
        module.setMaximumIssuanceRate(0.5e18);
    }

    function test_setMaximumIssuanceRate_notScheduled() external {
        globals.__setIsValidScheduledCall(false);

        vm.expectRevert("IM:NOT_SCHEDULED");
        module.setMaximumIssuanceRate(0.5e18);
    }

    function test_setMaximumIssuanceRate_success() external {
        globals.__expectCall();
        globals.unscheduleCall(governor, "IM:SMIR", abi.encodeWithSelector(module.setMaximumIssuanceRate.selector, 0.5e18));

        module.setMaximumIssuanceRate(0.5e18);

        assertEq(module.maximumIssuanceRate(), 0.5e18);
    }

}
