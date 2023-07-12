// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

import { NonTransparentProxy } from "../../modules/ntp/contracts/NonTransparentProxy.sol";

import { IEmergencyModule } from "../../contracts/interfaces/IEmergencyModule.sol";
import { IInflationModule } from "../../contracts/interfaces/IInflationModule.sol";
import { IMapleToken }      from "../../contracts/interfaces/IMapleToken.sol";

import { EmergencyModule }       from "../../contracts/EmergencyModule.sol";
import { InflationModule }       from "../../contracts/InflationModule.sol";
import { MapleToken }            from "../../contracts/MapleToken.sol";
import { MapleTokenInitializer } from "../../contracts/MapleTokenInitializer.sol";
import { MapleTokenProxy }       from "../../contracts/MapleTokenProxy.sol";

import { IGlobalsLike } from "../utils/Interfaces.sol";
import { TestBase }     from "../utils/TestBase.sol";

import { Invariants } from "./Invariants.sol";
import { Selector }   from "./Selector.sol";

contract InvariantTests is TestBase {

    address governor = makeAddr("governor");
    address migrator = makeAddr("migrator");
    address treasury = makeAddr("treasury");

    uint32 start = uint32(block.timestamp);

    IEmergencyModule emergencyModule;
    IInflationModule inflationModule;
    IGlobalsLike     mapleGlobals;
    IMapleToken      mapleToken;

    function setUp() external {
        mapleGlobals = IGlobalsLike(address(new NonTransparentProxy(governor, deployGlobals())));
        mapleToken   = IMapleToken(address(new MapleTokenProxy(
            address(mapleGlobals),
            address(new MapleToken()),
            address(new MapleTokenInitializer()),
            migrator
        )));

        emergencyModule = new EmergencyModule(address(mapleGlobals), address(mapleToken));
        inflationModule = new InflationModule(address(mapleToken), 1e18);

        vm.startPrank(governor);

        mapleGlobals.setMapleTreasury(treasury);

        mapleGlobals.scheduleCall(
            address(mapleToken),
            "MT:ADD_MODULE",
            abi.encodeWithSelector(MapleToken.addModule.selector, address(emergencyModule))
        );

        mapleToken.addModule(address(emergencyModule));

        mapleGlobals.scheduleCall(
            address(mapleToken),
            "MT:ADD_MODULE",
            abi.encodeWithSelector(MapleToken.addModule.selector, address(inflationModule))
        );

        mapleToken.addModule(address(inflationModule));

        vm.stopPrank();
    }

    function statefulFuzz_assertInvariants() external {
        // TODO: Configure contracts, functions, weights, etc.

        targetContract(address(new Selector()));

        Invariants.assert_inflationModule_invariant_A(inflationModule);
        Invariants.assert_inflationModule_invariant_B(inflationModule);
        Invariants.assert_inflationModule_invariant_C(inflationModule);
        Invariants.assert_inflationModule_invariant_D(inflationModule);
        Invariants.assert_inflationModule_invariant_E(inflationModule);
        Invariants.assert_inflationModule_invariant_F(inflationModule);
        Invariants.assert_inflationModule_invariant_G(inflationModule);
        Invariants.assert_inflationModule_invariant_H(inflationModule);
        Invariants.assert_inflationModule_invariant_I(inflationModule);
        Invariants.assert_inflationModule_invariant_J(inflationModule);
    }

}
