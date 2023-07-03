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

    InflationModule          module;
    InflationModule.Window[] windows;

    function setUp() public virtual {
        globals = new MockGlobals();
        token   = new MockToken();

        globals.__setGovernor(governor);
        globals.__setMapleTreasury(treasury);

        module = new InflationModule(address(globals), address(token));

        vm.startPrank(governor);
        vm.warp(start);
    }

    function assertWindow(uint256 windowId, uint32 windowStart, uint224 issuanceRate) internal {
        ( uint32 windowStart_, uint224 issuanceRate_ ) = module.windows(windowId);

        assertEq(windowStart_,  windowStart,  "windowStart");
        assertEq(issuanceRate_, issuanceRate, "issuanceRate");
    }

}

contract ConstructorTests is InflationModuleTestBase {

    function test_inflationModule_constructor() external {
        assertEq(module.PRECISION(), 1e30);

        assertEq(module.globals(), address(globals));
        assertEq(module.token(),   address(token));

        assertEq(module.lastMinted(),  0);
        assertEq(module.windowCount(), 0);

        assertEq(module.mintable(0, type(uint32).max), 0);
    }

}

contract MintableTests is InflationModuleTestBase {

    // TODO

}

contract MintTests is InflationModuleTestBase {


    function test_mint_notGovernor() external {
        // TODO: Decide if function should be permissioned.
    }

    function test_mint_duringInitialization() external {
        // TODO
    }

    function test_mint_afterInitialization() external {
        // TODO
    }

    function test_mint_zeroIssuanceRate() external {
        // TODO
    }

    function test_mint_beforeSchedule() external {
        // TODO
    }

    function test_mint_duringSchedule() external {
        // TODO
    }

    function test_mint_afterSchedule() external {
        // TODO
    }

}

contract ScheduleTests is InflationModuleTestBase {

    function test_schedule_notGovernor() external {
        vm.stopPrank();
        vm.expectRevert("IM:NOT_GOVERNOR");
        module.schedule(windows);
    }

    function test_schedule_noWindows() external {
        vm.expectRevert("IM:VW:NO_WINDOWS");
        module.schedule(windows);
    }

    function test_schedule_outOfDate() external {
        windows.push(InflationModule.Window(start - 1 seconds, 1e30));

        vm.expectRevert("IM:VW:OUT_OF_DATE");
        module.schedule(windows);

        windows[0] = InflationModule.Window(start, 1e30);

        module.schedule(windows);
    }

    function test_schedule_outOfOrder() external {
        windows.push(InflationModule.Window(start, 1e30));
        windows.push(InflationModule.Window(start, 1.1e30));

        vm.expectRevert("IM:VW:OUT_OF_ORDER");
        module.schedule(windows);

        windows[1] = InflationModule.Window(start + 1 seconds, 1e30);

        module.schedule(windows);
    }

    function test_schedule_basic() external {
        windows.push(InflationModule.Window(start + 10 days, 1e30));

        module.schedule(windows);

        assertEq(module.windowCount(), 1);

        assertWindow(0, start + 10 days, 1e30);
    }

    function test_schedule_simultaneously() external {
        windows.push(InflationModule.Window(start + 10 days, 1e30));
        windows.push(InflationModule.Window(start + 90 days, 1.1e30));

        module.schedule(windows);

        assertEq(module.windowCount(), 2);

        assertWindow(0, start + 10 days, 1e30);
        assertWindow(1, start + 90 days, 1.1e30);
    }

    function test_schedule_sequentially() external {
        windows.push(InflationModule.Window(start + 10 days, 1e30));

        module.schedule(windows);

        windows[0] = InflationModule.Window(start + 90 days, 1.1e30);

        module.schedule(windows);

        assertEq(module.windowCount(), 2);

        assertWindow(0, start + 10 days, 1e30);
        assertWindow(1, start + 90 days, 1.1e30);
    }

    function test_schedule_sequentially_withWarp() external {
        // TODO
    }

    function test_schedule_replacement() external {
        // TODO
    }

    function test_schedule_insertion() external {
        // TODO
    }

    function test_schedule_all() external {
        // TODO
    }

}
