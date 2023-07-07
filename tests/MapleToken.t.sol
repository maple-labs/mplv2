// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

import { TestBase } from "./utils/TestBase.sol";

import { MapleToken }            from "../contracts/MapleToken.sol";
import { MapleTokenInitializer } from "../contracts/MapleTokenInitializer.sol";
import { MapleTokenProxy }       from "../contracts/MapleTokenProxy.sol";

import { MockGlobals } from "./utils/Mocks.sol";

contract MapleTokenTestsBase is TestBase {

    address governor = makeAddr("governor");
    address migrator = makeAddr("migrator");
    address treasury = makeAddr("treasury");

    address implementation;
    address initializer;
    address tokenAddress;

    MockGlobals globals;
    MapleToken  token;

    function setUp() public virtual {
        globals = new MockGlobals();

        globals.__setGovernor(governor);
        globals.__setMapleTreasury(treasury);
        globals.__setIsValidScheduledCall(true);

        implementation = address(new MapleToken());
        initializer    = address(new MapleTokenInitializer());
        tokenAddress   = address(new MapleTokenProxy(address(globals), implementation, initializer, migrator));

        token = MapleToken(tokenAddress);
    }

}

contract SetImplementationTests is MapleTokenTestsBase {

    function test_setImplementation_notAdmin() external {
        vm.expectRevert("MTP:SI:NOT_ADMIN");
        MapleTokenProxy(tokenAddress).setImplementation(address(0x1));
    }

    function test_setImplementation_notScheduled() external {
        globals.__setIsValidScheduledCall(false);

        vm.prank(governor);
        vm.expectRevert("MTP:SI:NOT_SCHEDULED");
        MapleTokenProxy(tokenAddress).setImplementation(address(0x1));
    }

    function test_setImplementation_success() external {
        address newImplementation = address(new MapleToken());

        globals.__expectCall();
        globals.unscheduleCall(
            governor,
            bytes32("MTP:SET_IMPLEMENTATION"),
            abi.encodeWithSelector(MapleTokenProxy(tokenAddress).setImplementation.selector, newImplementation)
        );

        vm.prank(governor);
        MapleTokenProxy(tokenAddress).setImplementation(newImplementation);

        assertEq(MapleToken(tokenAddress).implementation(), newImplementation);
    }

}

contract AddAndRemoveModuleTests is MapleTokenTestsBase {

    function test_addModule_notGovernor() external {
        vm.expectRevert("MT:NOT_GOVERNOR");
        token.addModule(address(0x1));
    }

    function test_addModule_notScheduled() external {
        globals.__setIsValidScheduledCall(false);

        vm.prank(governor);
        vm.expectRevert("MT:NOT_SCHEDULED");
        token.addModule(address(0x1));
    }

    function test_addModule_success() external {
        globals.__expectCall();
        globals.unscheduleCall(
            governor,
            bytes32("MT:ADD_MODULE"),
            abi.encodeWithSelector(token.addModule.selector, address(0x1))
        );

        vm.prank(governor);
        token.addModule(address(0x1));

        assertTrue(token.isModule(address(0x1)));
    }

    function test_removeModule_notGovernor() external {
        vm.expectRevert("MT:NOT_GOVERNOR");
        token.removeModule(address(0x1));
    }

    function test_removeModule_notScheduled() external {
        globals.__setIsValidScheduledCall(false);

        vm.prank(governor);
        vm.expectRevert("MT:NOT_SCHEDULED");
        token.removeModule(address(0x1));
    }

    function test_removeModule_success() external {
        vm.prank(governor);
        token.addModule(address(0x1));

        globals.__expectCall();
        globals.unscheduleCall(
            governor,
            bytes32("MT:REMOVE_MODULE"),
            abi.encodeWithSelector(token.removeModule.selector, address(0x1))
        );

        vm.prank(governor);
        token.removeModule(address(0x1));

        assertTrue(!token.isModule(address(0x1)));
    }

}

contract BurnTests is MapleTokenTestsBase {

    address burner    = makeAddr("burner");
    address notBurner = makeAddr("notBurner");

    function setUp() public override {
        super.setUp();

        vm.prank(governor);
        token.addModule(address(burner));
    }

    function test_burn_notBurner() external {
        vm.prank(notBurner);
        vm.expectRevert("MT:B:NOT_MODULE");
        token.burn(address(0x1), 1);
    }

    function test_burn_noBalance() external {
        vm.prank(burner);
        vm.expectRevert(arithmeticError);
        token.burn(treasury, type(uint256).max);

        vm.prank(burner);
        token.burn(treasury, 100);

        assertEq(token.balanceOf(treasury), 1_000_000e18 - 100);
    }

    function test_burn_success() external {
        vm.prank(burner);
        token.burn(treasury, 1);

        assertEq(token.balanceOf(treasury), 1_000_000e18 - 1);
    }

}

contract MintTests is MapleTokenTestsBase {

    address minter =  makeAddr("minter");

    function setUp() public override {
        super.setUp();

        vm.prank(governor);
        token.addModule(address(minter));
    }

     function test_mint_notMinter() external {
        vm.expectRevert("MT:M:NOT_MODULE");
        token.mint(address(0x2), 1);
    }

    function test_burn_success() external {
        vm.prank(minter);
        token.mint(address(0x2), 1);

        assertEq(token.balanceOf(address(0x2)), 1);
    }

}
