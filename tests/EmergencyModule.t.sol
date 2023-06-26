// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

import { TestBase } from "./utils/TestBase.sol";

import { EmergencyModule } from "../contracts/EmergencyModule.sol";

import { MockGlobals, MockToken } from "./utils/Mocks.sol";

contract EmergencyModuleTets is TestBase {

    address governor = makeAddr("governor");
    address treasury = makeAddr("treasury");

    MockGlobals     globals;
    MockToken       token;
    EmergencyModule emergencyModule;

    function setUp() external {
        globals = new MockGlobals();
        globals.__setGovernor(governor);
        globals.__setMapleTreasury(treasury);

        token           = new MockToken();
        emergencyModule = new EmergencyModule(address(token), address(globals));
    }

    function test_constructor() external {
        assertEq(emergencyModule.globals(), address(globals));
        assertEq(emergencyModule.token(),   address(token));
    }

    function test_mint_notGovernor() external {
        vm.expectRevert("EM:NOT_GOVERNOR");
        emergencyModule.mint(1);
    }

    function test_mint_success() external {
        token.__expectCall();
        token.mint(treasury, 1);

        vm.prank(governor);
        emergencyModule.mint(1);
    }

    function test_burn_notGovernor() external {
        vm.expectRevert("EM:NOT_GOVERNOR");
        emergencyModule.burn(address(0x1), 1);
    }

    function test_burn_success() external {
        token.__expectCall();
        token.burn(address(0x1), 1);

        vm.prank(governor);
        emergencyModule.burn(address(0x1), 1);
    }

}
