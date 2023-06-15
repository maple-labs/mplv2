// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

import { NonTransparentProxy } from "../../modules/ntp/contracts/NonTransparentProxy.sol";

import { IMapleToken }           from "../../contracts/interfaces/IMapleToken.sol";
import { MapleToken }            from "../../contracts/MapleToken.sol";
import { MapleTokenInitializer } from "../../contracts/MapleTokenInitializer.sol";
import { MapleTokenProxy }       from "../../contracts/MapleTokenProxy.sol";

import { TestBase }       from "../utils/TestBase.sol";
import { IGlobalsLike  }  from "../utils/Interfaces.sol";

contract AddModuleIntegrationTests is TestBase {

    address governor = makeAddr("governor");
    address treasury = makeAddr("treasury");
    address module   = makeAddr("module");

    uint256 start;

    IGlobalsLike globals;
    IMapleToken  token;

    function setUp() public virtual {
        globals = IGlobalsLike(address(new NonTransparentProxy(governor, deployGlobals())));
        token   = IMapleToken(address(new MapleTokenProxy(governor, address(new MapleToken()), address(new MapleTokenInitializer()), address(globals))));

        vm.prank(governor);
        globals.setTimelockWindow(address(token), "MT:ADD_MODULE", 7 days, 2 days);

        start = block.timestamp;
    }

    function test_addModule_notGovernor() external {
        vm.expectRevert("MT:NOT_GOVERNOR");
        token.addModule(module, false, true);
    }

    function test_addModule_notScheduled() external {
        vm.prank(governor);
        vm.expectRevert("MT:NOT_SCHEDULED");
        token.addModule(module, false, true);
    }

    function test_addModule_notScheduled_beforeDelay() external {
        vm.startPrank(governor);

        globals.scheduleCall(address(token), "MT:ADD_MODULE", abi.encodeWithSelector(IMapleToken.addModule.selector, module, false, true));

        vm.warp(start + 7 days - 1);

        vm.expectRevert("MT:NOT_SCHEDULED");
        token.addModule(module, false, true);

        vm.warp(start + 7 days + 1);

        token.addModule(module, false, true);

        vm.stopPrank();
    }

    function test_addModule_notScheduled_afterWindow() external {
        vm.startPrank(governor);

        globals.scheduleCall(address(token), "MT:ADD_MODULE", abi.encodeWithSelector(IMapleToken.addModule.selector, module, false, true));

        vm.warp(start + 9 days + 1);

        vm.expectRevert("MT:NOT_SCHEDULED");
        token.addModule(module, false, true);

        vm.warp(start + 9 days);

        token.addModule(module, false, true);

        vm.stopPrank();
    }

    function test_addModule_invalidModule() external {
        vm.startPrank(governor);
        globals.scheduleCall(address(token), "MT:ADD_MODULE", abi.encodeWithSelector(IMapleToken.addModule.selector, module, false, false));

        vm.warp(start + 8 days);

        vm.expectRevert("MT:AM:INVALID_MODULE");
        token.addModule(module, false, false);
        vm.stopPrank();
    }

    function test_addModule_create() external {
        vm.startPrank(governor);
        globals.scheduleCall(address(token), "MT:ADD_MODULE", abi.encodeWithSelector(IMapleToken.addModule.selector, module, false, true));

        vm.warp(start + 8 days);

        token.addModule(module, false, true);
        vm.stopPrank();

        assertTrue(!token.isBurner(module));
        assertTrue(token.isMinter(module));
    }

    function test_addModule_update() external {
        // Add the module
        vm.startPrank(governor);
        globals.scheduleCall(address(token), "MT:ADD_MODULE", abi.encodeWithSelector(IMapleToken.addModule.selector, module, false, true));

        vm.warp(start + 8 days);

        token.addModule(module, false, true);

        assertTrue(!token.isBurner(module));
        assertTrue(token.isMinter(module));

        globals.scheduleCall(address(token), "MT:ADD_MODULE", abi.encodeWithSelector(IMapleToken.addModule.selector, module, true, false));

        vm.warp(start + 16 days);

        token.addModule(module, true, false);

        assertTrue(token.isBurner(module));
        assertTrue(!token.isMinter(module));

        vm.stopPrank();
    }

}
