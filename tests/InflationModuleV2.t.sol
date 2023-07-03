// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

import { TestBase } from "./utils/TestBase.sol";

import { InflationModule } from "../contracts/InflationModuleV2.sol";

import { MockGlobals, MockToken } from "./utils/Mocks.sol";

contract InflationModuleTestBase is TestBase {

    address governor = makeAddr("governor");
    address treasury = makeAddr("treasury");

    uint32 start = uint32(block.timestamp);

    MockGlobals globals;
    MockToken   token;

    InflationModule module;

    function setUp() public virtual {
        globals = new MockGlobals();
        token   = new MockToken();

        globals.__setGovernor(governor);
        globals.__setMapleTreasury(treasury);

        module  = new InflationModule(address(globals), address(token));

        vm.startPrank(governor);
        vm.warp(start);
    }

    function assertWindow(uint16 windowId, uint16 nextWindowId, uint32 windowStart, uint192 issuanceRate) internal {
        (
            uint16  windowId_,
            uint16  nextWindowId_,
            uint32  windowStart_,
            uint192 issuanceRate_
        ) = module.windows(windowId);

        assertEq(windowId_,     windowId,     "windowId");
        assertEq(nextWindowId_, nextWindowId, "nextWindowId");
        assertEq(windowStart_,  windowStart,  "windowStart");
        assertEq(issuanceRate_, issuanceRate, "issuanceRate");
    }

}
contract ConstructorTests is InflationModuleTestBase {

    function test_inflationModule_constructor() external {
        assertEq(module.PRECISION(), 1e30);

        assertEq(module.globals(), address(globals));
        assertEq(module.token(),   address(token));

        assertEq(module.currentWindowId(),     0);
        assertEq(module.lastClaimed(),         0);
        assertEq(module.windowCounter(),       1);
        assertEq(module.maximumIssuanceRate(), 1e30);

        assertWindow(0, 0, 0, 0);
    }
}

// contract IssuableAtTests is InflationModuleTestBase {
//     function test_issuableAt_outOfDate() external {
//         // TODO
//     }
//     function test_issuableAt_nothingIssued() external {
//         // TODO
//     }
//     function test_issuableAt_oneSchedule_fromStart_oneDayAhead() external {
//         // TODO
//     }
//     function test_issuableAt_oneSchedule_fromStart_toCurrentTime() external {
//         // TODO
//     }
//     function test_issuableAt_oneSchedule_afterIssuance_oneDayHead() external {
//         // TODO
//     }
//     function test_issuableAt_oneSchedule_afterIssuance_toCurrentTime() external {
//         // TODO
//     }
//     function test_issuableAt_twoSchedules_fromStart_beforeFirstSchedule() external {
//         // TODO
//     }
//     function test_issuableAt_twoSchedules_fromStart_beforeSecondSchedule() external {
//         // TODO
//     }
//     function test_issuableAt_twoSchedules_fromStart_afterSecondSchedule() external {
//         // TODO
//     }
// }
// contract IssueTests is InflationModuleTestBase {
//     // TODO: Decide if function should be permissioned.
//     // function test_issue_notGovernor() external {
//     //     vm.stopPrank();
//     //     vm.expectRevert("IM:NOT_GOVERNOR");
//     //     module.issue();
//     // }
//     function test_issue_duringInitialization() external {
//         module.issue();

//         assertEq(module.lastIssued(),     start);
//         assertEq(module.lastScheduleId(), 0);
//         assertEq(module.scheduleCount(),  1);
//     }

//     function test_issue_afterInitialization() external {
//         vm.warp(start + 150 seconds);
//         module.issue();

//         assertEq(module.lastIssued(),     start + 150 seconds);
//         assertEq(module.lastScheduleId(), 0);
//         assertEq(module.scheduleCount(),  1);
//     }

//     function test_issue_beforeSchedule() external {
//         module.schedule(start + 100 days, 1e30);
//         vm.warp(start + 80 days);
//         module.issue();

//         assertEq(module.lastIssued(),     start + 80 days);
//         assertEq(module.lastScheduleId(), 0);
//         assertEq(module.scheduleCount(),  2);

//         assertSchedule(0, 1, 0,                0);
//         assertSchedule(1, 0, start + 100 days, 1e30);
//     }

// }
// contract ScheduleTests is InflationModuleTestBase {
//     function test_schedule_notGovernor() external {
//         vm.stopPrank();
//         vm.expectRevert("IM:NOT_GOVERNOR");
//         module.schedule(start, 1e30);
//     }
//     function test_schedule_firstSchedule_outOfDate() external {
//         vm.expectRevert("IM:S:OUT_OF_DATE");
//         module.schedule(start - 1 seconds, 1e30);
//         module.schedule(start, 1e30);
//     }
//     function test_schedule_secondSchedule_outOfDate() external {
//         module.schedule(start, 1e30);
//         vm.warp(start + 10 days);
//         vm.expectRevert("IM:S:OUT_OF_DATE");
//         module.schedule(start + 10 days - 1 seconds, 1e30);
//         module.schedule(start + 10 days, 1e30);
//     }
//     function test_schedule_firstSchedule() external {
//         module.schedule(start, 1e30);

//         assertEq(module.scheduleCount(), 2);

//         assertSchedule(0, 1, 0,     0);
//         assertSchedule(1, 0, start, 1e30);
//     }

//     function test_schedule_twoSchedules_ascending() external {
//         module.schedule(start + 10 days,  1e30);
//         module.schedule(start + 175 days, 1.1e30);

//         assertEq(module.scheduleCount(), 3);

//         assertSchedule(0, 1, 0,                0);
//         assertSchedule(1, 2, start + 10 days,  1e30);
//         assertSchedule(2, 0, start + 175 days, 1.1e30);
//     }

//     function test_schedule_twoSchedules_descending() external {
//         module.schedule(start + 65 days, 1.1e30);
//         module.schedule(start + 15 days, 1e30);

//         assertEq(module.scheduleCount(), 3);

//         assertSchedule(0, 2, 0,               0);
//         assertSchedule(1, 0, start + 65 days, 1.1e30);
//         assertSchedule(2, 1, start + 15 days, 1e30);
//     }

//     function test_schedule_threeSchedules_withInsert() external {
//         module.schedule(start + 50 days,  1e30);
//         module.schedule(start + 100 days, 1.1e30);
//         module.schedule(start + 75 days,  1.05e30);

//         assertEq(module.scheduleCount(), 4);

//         assertSchedule(0, 1, 0,                0);
//         assertSchedule(1, 3, start + 50 days,  1e30);
//         assertSchedule(2, 0, start + 100 days, 1.1e30);
//         assertSchedule(3, 2, start + 75 days,  1.05e30);
//     }

//     function test_schedule_threeSchedules_withInsertAndUpdate() external {
//         module.schedule(start + 50 days,  1.05e30);
//         module.schedule(start + 100 days, 1.1e30);
//         module.schedule(start + 45 days,  1e30);

//         assertEq(module.scheduleCount(), 4);

//         assertSchedule(0, 3, 0,                0);
//         assertSchedule(1, 2, start + 50 days,  1.05e30);
//         assertSchedule(2, 0, start + 100 days, 1.1e30);
//         assertSchedule(3, 1, start + 45 days,  1e30);
//     }

// }
