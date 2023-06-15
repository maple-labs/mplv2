// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

import { TestBase } from "./utils/TestBase.sol";

import { MapleTokenProxy } from "../contracts/MapleTokenProxy.sol";
import { MapleToken }      from "../contracts/MapleToken.sol";

import { MockGlobals } from "./utils/Mocks.sol";

contract MapleTokenTestsBase is TestBase {

    address governor = makeAddr("governor");

    address implementation;
    address token;

    MockGlobals globals;

    function setUp() public virtual {
        globals = new MockGlobals();
        globals.__setGovernor(governor);

        implementation = address(new MapleToken("MPL", "MPL", 18));
        token          = address(new MapleTokenProxy(governor, (implementation), address(globals)));
    }

}

contract ProxyTests is MapleTokenTestsBase {

    function test_proxySetup() external {
        MapleToken token_ = MapleToken(token);

        assertEq(token_.implementation(), address(implementation));
        assertEq(token_.globals(),        address(globals));
        assertEq(token_.admin(),          governor);

        // TODO test symbol, name and decimals once constructor issue is fixed
    }
    
}

contract SetImplementationTests is MapleTokenTestsBase {
    
    function test_setImplementation_notAdmin() external {
        vm.expectRevert("NTP:SI:NOT_ADMIN");
        MapleTokenProxy(token).setImplementation(address(0x1));
    }

    function test_setImplementation_success() external {
        address newImplementation = address(new MapleToken("MPL", "MPL", 18));

        vm.prank(governor);
        MapleTokenProxy(token).setImplementation(newImplementation);
    }
}
