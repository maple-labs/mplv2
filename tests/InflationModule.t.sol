// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

import { InflationModule } from "../contracts/InflationModule.sol";

import { MockGlobals, MockToken } from "./utils/Mocks.sol";
import { TestBase }               from "./utils/TestBase.sol";

// TODO: Add fuzz tests.
// TODO: Check if events are correctly emitted.
// TODO: Check if function return values are correct (not just state changes).

contract InflationModuleTestBase is TestBase {

    address governor;
    address treasury;

    uint32 start;

    uint32[] windowStarts;

    uint208[] issuanceRates;

    MockGlobals globals;
    MockToken   token;

    InflationModule module;

    function setUp() public virtual {
        governor = makeAddr("governor");
        treasury = makeAddr("treasury");

        globals = new MockGlobals();
        globals.__setGovernor(governor);
        globals.__setMapleTreasury(treasury);
        globals.__setIsValidScheduledCall(true);

        token = new MockToken();
        token.__setGlobals(address(globals));

        module = new InflationModule(address(token), 1e18);

        start = uint32(block.timestamp);

        vm.startPrank(governor);
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

    function expectTreasuryMint(uint256 amount) internal {
        token.__expectCall();
        token.mint(treasury, amount);
    }

    function expectUnscheduleCall() internal {
        globals.__expectCall();
        globals.unscheduleCall(governor, "IM:SCHEDULE", abi.encodeWithSelector(module.schedule.selector, windowStarts, issuanceRates));
    }

}

contract ConstructorTests is InflationModuleTestBase {

    function test_inflationModule_constructor() external {
        assertEq(module.token(), address(token));

        assertEq(module.maximumIssuanceRate(), 1e18);

        assertEq(module.lastClaimedTimestamp(),  0);
        assertEq(module.lastClaimedWindowId(),   0);
        assertEq(module.lastScheduledWindowId(), 0);

        assertWindow(0, 0, 0, 0);
    }
}

contract ClaimTests is InflationModuleTestBase {

    event Claimed(uint256 amountClaimed, uint16 lastClaimedWindowId);

    function setUp() public override {
        super.setUp();

        vm.stopPrank();
    }

    function test_claim_zeroClaim_atomic() external {
        vm.expectRevert("IM:C:ZERO_CLAIM");
        module.claim();
    }

    function test_claim_zeroClaim_afterWarp() external {
        vm.warp(start + 10 days);
        vm.expectRevert("IM:C:ZERO_CLAIM");
        module.claim();
    }

    function test_claim_zeroClaim_emptyWindow() external {
        windowStarts.push(start + 5 days);
        issuanceRates.push(0);

        vm.prank(governor);
        module.schedule(windowStarts, issuanceRates);

        vm.warp(start + 10 days);
        vm.expectRevert("IM:C:ZERO_CLAIM");
        module.claim();
    }

    function test_claim_zeroClaim_beforeWindow() external {
        windowStarts.push(start + 20 days);
        issuanceRates.push(1e18);

        vm.prank(governor);
        module.schedule(windowStarts, issuanceRates);

        vm.warp(start + 10 days);
        vm.expectRevert("IM:C:ZERO_CLAIM");
        module.claim();
    }

    function test_claim_duringWindow() external {
        windowStarts.push(start);
        issuanceRates.push(1e18);

        vm.warp(start);
        vm.prank(governor);
        module.schedule(windowStarts, issuanceRates);

        vm.warp(start + 40 days);

        uint256 expectedClaim = 1e18 * 40 days;

        assertEq(module.claimable(start + 40 days), expectedClaim);

        expectTreasuryMint(expectedClaim);
        uint256 actualClaim = module.claim();

        assertEq(actualClaim, expectedClaim);

        assertEq(module.lastClaimedTimestamp(), start + 40 days);
        assertEq(module.lastClaimedWindowId(),  1);
    }

    function test_claim_afterWindow() external {
        windowStarts.push(start);
        windowStarts.push(start + 50 days);

        issuanceRates.push(1e18);
        issuanceRates.push(0);

        vm.warp(start);
        vm.prank(governor);
        module.schedule(windowStarts, issuanceRates);

        vm.warp(start + 65 days);

        uint256 expectedClaim = 1e18 * 50 days;

        assertEq(module.claimable(start + 65 days), expectedClaim);

        expectTreasuryMint(expectedClaim);
        uint256 actualClaim = module.claim();

        assertEq(actualClaim, expectedClaim);

        assertEq(module.lastClaimedTimestamp(), start + 65 days);
        assertEq(module.lastClaimedWindowId(),  2);
    }

    function test_claim_betweenWindows() external {
        windowStarts.push(start);
        windowStarts.push(start + 50 days);

        issuanceRates.push(1e18);
        issuanceRates.push(0);

        vm.warp(start);
        vm.prank(governor);
        module.schedule(windowStarts, issuanceRates);

        vm.warp(start + 50 days);

        uint256 expectedClaim = 1e18 * 50 days;

        assertEq(module.claimable(start + 50 days), expectedClaim);

        expectTreasuryMint(expectedClaim);
        uint256 actualClaim = module.claim();

        assertEq(actualClaim, expectedClaim);

        assertEq(module.lastClaimedTimestamp(), start + 50 days);
        assertEq(module.lastClaimedWindowId(),  2);
    }

    function test_claim_threeWindows() external {
        windowStarts.push(start);
        windowStarts.push(start + 50 days);
        windowStarts.push(start + 85 days);

        issuanceRates.push(0.95e18);
        issuanceRates.push(0.96e18);
        issuanceRates.push(0.97e18);

        vm.warp(start);
        vm.prank(governor);
        module.schedule(windowStarts, issuanceRates);

        vm.warp(start + 65 days);

        uint256 expectedClaim =  0.95e18 * 50 days + 0.96e18 * 15 days;

        assertEq(module.claimable(start + 65 days), expectedClaim);

        expectTreasuryMint(expectedClaim);
        uint256 actualClaim = module.claim();

        assertEq(actualClaim, expectedClaim);

        assertEq(module.lastClaimedTimestamp(), start + 65 days);
        assertEq(module.lastClaimedWindowId(),  2);
    }

    function test_claim_sevenWindows() external {
        windowStarts.push(start);
        windowStarts.push(start + 50 days);
        windowStarts.push(start + 85 days);
        windowStarts.push(start + 120 days);
        windowStarts.push(start + 150 days);
        windowStarts.push(start + 190 days);
        windowStarts.push(start + 300 days);

        issuanceRates.push(0.95e18);
        issuanceRates.push(0.96e18);
        issuanceRates.push(0.97e18);
        issuanceRates.push(0);
        issuanceRates.push(1e18);
        issuanceRates.push(0);
        issuanceRates.push(0.98e18);

        vm.warp(start);
        vm.prank(governor);
        module.schedule(windowStarts, issuanceRates);

        vm.warp(start + 20 days);
        expectTreasuryMint(0.95e18 * 20 days);
        module.claim();

        assertEq(module.lastClaimedTimestamp(), start + 20 days);
        assertEq(module.lastClaimedWindowId(),  1);

        vm.warp(start + 60 days);
        expectTreasuryMint(0.95e18 * 30 days + 0.96e18 * 10 days);
        module.claim();

        assertEq(module.lastClaimedTimestamp(), start + 60 days);
        assertEq(module.lastClaimedWindowId(),  2);

        vm.warp(start + 100 days);
        expectTreasuryMint(0.96e18 * 25 days + 0.97e18 * 15 days);
        module.claim();

        assertEq(module.lastClaimedTimestamp(), start + 100 days);
        assertEq(module.lastClaimedWindowId(),  3);

        vm.warp(start + 200 days);
        expectTreasuryMint(0.97e18 * 20 days + 1e18 * 40 days);
        module.claim();

        assertEq(module.lastClaimedTimestamp(), start + 200 days);
        assertEq(module.lastClaimedWindowId(),  6);
    }

    function test_claim_afterReschedule() external {
        // TODO
    }

}


contract ScheduleTests is InflationModuleTestBase {

    event WindowsScheduled(uint16 firstWindowId, uint16 lastWindowId, uint32[] windowStarts, uint208[] issuanceRates);

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

        vm.expectEmit();
        emit WindowsScheduled(1, 1, windowStarts, issuanceRates);

        module.schedule(windowStarts, issuanceRates);

        assertEq(module.lastScheduledWindowId(), 1);

        assertWindow(0, 1, 0,               0);
        assertWindow(1, 0, start + 10 days, 0.9e18);
    }

    function test_schedule_simultaneously() external {
        windowStarts.push(start + 10 days);
        windowStarts.push(start + 100 days);

        issuanceRates.push(0.9e18);
        issuanceRates.push(0.95e18);

        expectUnscheduleCall();

        vm.expectEmit();
        emit WindowsScheduled(1, 2, windowStarts, issuanceRates);

        module.schedule(windowStarts, issuanceRates);

        assertEq(module.lastScheduledWindowId(), 2);

        assertWindow(0, 1, 0,                0);
        assertWindow(1, 2, start + 10 days,  0.9e18);
        assertWindow(2, 0, start + 100 days, 0.95e18);
    }

    function test_schedule_sequentially() external {
        windowStarts.push(start + 10 days);
        issuanceRates.push(0.9e18);

        expectUnscheduleCall();

        vm.expectEmit();
        emit WindowsScheduled(1, 1, windowStarts, issuanceRates);

        module.schedule(windowStarts, issuanceRates);

        windowStarts[0] = start + 100 days;
        issuanceRates[0] = 0.95e18;

        expectUnscheduleCall();

        vm.expectEmit();
        emit WindowsScheduled(2, 2, windowStarts, issuanceRates);

        module.schedule(windowStarts, issuanceRates);

        assertEq(module.lastScheduledWindowId(), 2);

        assertWindow(0, 1, 0,                0);
        assertWindow(1, 2, start + 10 days,  0.9e18);
        assertWindow(2, 0, start + 100 days, 0.95e18);
    }

    function test_schedule_sequentiallyWithWarp() external {
        windowStarts.push(start + 10 days);
        issuanceRates.push(0.9e18);

        expectUnscheduleCall();

        vm.expectEmit();
        emit WindowsScheduled(1, 1, windowStarts, issuanceRates);

        vm.warp(start + 5 days);
        module.schedule(windowStarts, issuanceRates);

        windowStarts[0] = start + 100 days;
        issuanceRates[0] = 0.95e18;

        expectUnscheduleCall();
        vm.warp(start + 95 days);

        vm.expectEmit();
        emit WindowsScheduled(2, 2, windowStarts, issuanceRates);

        module.schedule(windowStarts, issuanceRates);

        assertEq(module.lastScheduledWindowId(), 2);

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

        vm.expectEmit();
        emit WindowsScheduled(1, 2, windowStarts, issuanceRates);

        module.schedule(windowStarts, issuanceRates);

        windowStarts[0] = start + 150 days;
        windowStarts[1] = start + 200 days;

        issuanceRates[0] = 0.96e18;
        issuanceRates[1] = 0.99e18;

        expectUnscheduleCall();

        vm.expectEmit();
        emit WindowsScheduled(3, 4, windowStarts, issuanceRates);

        module.schedule(windowStarts, issuanceRates);

        assertEq(module.lastScheduledWindowId(), 4);

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

        vm.expectEmit();
        emit WindowsScheduled(1, 2, windowStarts, issuanceRates);

        module.schedule(windowStarts, issuanceRates);

        windowStarts[0] = start + 50 days;
        windowStarts[1] = start + 120 days;

        issuanceRates[0] = 0.96e18;
        issuanceRates[1] = 0.99e18;

        expectUnscheduleCall();

        vm.expectEmit();
        emit WindowsScheduled(3, 4, windowStarts, issuanceRates);

        module.schedule(windowStarts, issuanceRates);

        assertEq(module.lastScheduledWindowId(), 4);

        assertWindow(0, 1, 0,                0);
        assertWindow(1, 3, start + 10 days,  0.9e18);
        assertWindow(3, 4, start + 50 days,  0.96e18);
        assertWindow(4, 0, start + 120 days, 0.99e18);
    }

}
