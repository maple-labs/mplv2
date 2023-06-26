// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

import { NonTransparentProxy } from "../../modules/ntp/contracts/NonTransparentProxy.sol";

import { EmergencyModule }       from "../../contracts/EmergencyModule.sol";
import { IMapleToken }           from "../../contracts/interfaces/IMapleToken.sol";
import { MapleToken }            from "../../contracts/MapleToken.sol";
import { MapleTokenInitializer } from "../../contracts/MapleTokenInitializer.sol";
import { MapleTokenProxy }       from "../../contracts/MapleTokenProxy.sol";

import { TestBase }       from "../utils/TestBase.sol";
import { IGlobalsLike  }  from "../utils/Interfaces.sol";

contract EmergencyModuleIntegrationTest is TestBase {

    address governor = makeAddr("governor");
    address treasury = makeAddr("treasury");
    address migrator = makeAddr("migrator");

    uint256 start;

    EmergencyModule module;
    IGlobalsLike    globals;
    IMapleToken     token;

    function setUp() public virtual {
        globals = IGlobalsLike(address(new NonTransparentProxy(governor, deployGlobals())));
        
        vm.prank(governor);
        globals.setMapleTreasury(treasury);

        token   = IMapleToken(address(new MapleTokenProxy(address(globals), address(new MapleToken()), address(new MapleTokenInitializer()), migrator)));
        module  = new EmergencyModule(address(token), address(globals));

        vm.startPrank(governor);        
        globals.scheduleCall(address(token), "MT:ADD_MODULE", abi.encodeWithSelector(IMapleToken.addModule.selector, module, true, true));

        token.addModule(address(module), true, true);
        vm.stopPrank();

        start = block.timestamp;
    }

    function test_emergencyModule_mint_notGovernor() external {
        vm.expectRevert("EM:NOT_GOVERNOR");
        module.mint(1e18);
    }

    function test_emergencyModule_mint_notMinter() external {
        vm.startPrank(governor);        
        globals.scheduleCall(address(token), "MT:ADD_MODULE", abi.encodeWithSelector(IMapleToken.addModule.selector, module, true, false));

        token.addModule(address(module), true, false);

        vm.expectRevert("MT:M:NOT_MINTER");
        module.mint(1e18);

        vm.stopPrank();
    }

    function test_emergencyModule_mint_success() external {
        uint256 startingBalance = token.balanceOf(treasury);
        uint256 supply          = token.totalSupply();
        uint256 mintAmount      = 1_000e18;

        vm.prank(governor);
        module.mint(mintAmount);

        assertEq(token.balanceOf(treasury), startingBalance + mintAmount);
        assertEq(token.totalSupply(),       supply + mintAmount);
    }

    function test_emergencyModule_burn_notGovernor() external {
        vm.expectRevert("EM:NOT_GOVERNOR");
        module.burn(treasury, 1e18);
    }

    function test_emergencyModule_burn_notBurner() external {
        vm.startPrank(governor);        
        globals.scheduleCall(address(token), "MT:ADD_MODULE", abi.encodeWithSelector(IMapleToken.addModule.selector, module, false, true));

        token.addModule(address(module), false, true);

        vm.expectRevert("MT:B:NOT_BURNER");
        module.burn(treasury, 1e18);

        vm.stopPrank();
    }

    function test_emergencyModule_burn_success() external {
        uint256 startingBalance = token.balanceOf(treasury);
        uint256 supply          = token.totalSupply();
        uint256 burnAmount      = 1_000e18;

        vm.prank(governor);
        module.burn(treasury, burnAmount);

        assertEq(token.balanceOf(treasury), startingBalance - burnAmount);
        assertEq(token.totalSupply(),       supply - burnAmount);
    }

}
