// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

import { TestBase } from "./utils/TestBase.sol";

import { MapleToken }            from "../contracts/MapleToken.sol";
import { MapleTokenInitializer } from "../contracts/MapleTokenInitializer.sol";
import { MapleTokenProxy }       from "../contracts/MapleTokenProxy.sol";

import { MockGlobals } from "./utils/Mocks.sol";

contract MapleTokenInitializerTests is TestBase {

    address governor;
    address migrator;
    address treasury;

    address implementation;
    address initializer;

    MockGlobals globals;

    function setUp() external {
        governor = makeAddr("governor");
        migrator = makeAddr("migrator");
        treasury = makeAddr("treasury");

        globals = new MockGlobals();

        globals.__setGovernor(governor);
        globals.__setMapleTreasury(treasury);

        implementation = address(new MapleToken());
        initializer    = address(new MapleTokenInitializer());
    }

    function test_initialize() external {
        MapleToken token = MapleToken(address(new MapleTokenProxy(address(globals), implementation, initializer, migrator)));

        assertEq(token.admin(),          governor);
        assertEq(token.globals(),        address(globals));
        assertEq(token.implementation(), implementation);

        assertEq(token.name(),     "Maple Finance");
        assertEq(token.symbol(),   "MPL");
        assertEq(token.decimals(), 18);

        assertEq(token.balanceOf(migrator), 10_000_000e18);
        assertEq(token.balanceOf(treasury), 1_000_000e18);

        assertEq(token.totalSupply(), 11_000_000e18);
    }

}
