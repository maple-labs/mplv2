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

import { Handler }    from "./Handler.sol";
import { Invariants } from "./Invariants.sol";
import { Router }     from "./Router.sol";

contract InvariantTests is TestBase {

    address governor = makeAddr("governor");
    address migrator = makeAddr("migrator");
    address treasury = makeAddr("treasury");

    IGlobalsLike mapleGlobals;
    IMapleToken  mapleToken;

    IEmergencyModule emergencyModule;
    IInflationModule inflationModule;

    function setUp() external {
        deploy();
        configure();
        spec();
    }

    function deploy() internal {
        mapleGlobals = IGlobalsLike(address(new NonTransparentProxy(governor, deployGlobals())));
        mapleToken   = IMapleToken(address(new MapleTokenProxy(
            address(mapleGlobals),
            address(new MapleToken()),
            address(new MapleTokenInitializer()),
            migrator
        )));

        emergencyModule = new EmergencyModule(address(mapleGlobals), address(mapleToken));
        inflationModule = new InflationModule(address(mapleToken), 1e18);
    }

    function configure() internal {
        vm.startPrank(governor);

        mapleGlobals.setMapleTreasury(treasury);

        mapleGlobals.scheduleCall(
            address(mapleToken),
            "MT:ADD_MODULE",
            abi.encodeWithSelector(IMapleToken.addModule.selector, address(emergencyModule))
        );

        mapleToken.addModule(address(emergencyModule));

        mapleGlobals.scheduleCall(
            address(mapleToken),
            "MT:ADD_MODULE",
            abi.encodeWithSelector(IMapleToken.addModule.selector, address(inflationModule))
        );

        mapleToken.addModule(address(inflationModule));

        vm.stopPrank();
    }

    function spec() internal {
        Handler handler = new Handler(mapleGlobals, mapleToken, emergencyModule, inflationModule);

        bytes4[] memory selectors = new bytes4[](11);

        selectors[0]  = handler.approve.selector;
        selectors[1]  = handler.claim.selector;
        selectors[2]  = handler.decreaseAllowance.selector;
        selectors[3]  = handler.emergencyBurn.selector;
        selectors[4]  = handler.emergencyMint.selector;
        selectors[5]  = handler.increaseAllowance.selector;
        selectors[6]  = handler.permit.selector;
        selectors[7]  = handler.schedule.selector;
        selectors[8]  = handler.transfer.selector;
        selectors[9]  = handler.transferFrom.selector;
        selectors[10] = handler.warp.selector;

        uint256[] memory weights = new uint256[](11);

        weights[0]  = 1;
        weights[1]  = 100_000;
        weights[2]  = 1;
        weights[3]  = 1;
        weights[4]  = 1;
        weights[5]  = 1;
        weights[6]  = 1;
        weights[7]  = 100_000;
        weights[8]  = 1;
        weights[9]  = 1;
        weights[10] = 100_000;

        Router router = new Router(address(handler), selectors, weights);

        targetContract(address(router));
    }

    /**************************************************************************************************************************************/
    /*** Invariant Tests                                                                                                                ***/
    /**************************************************************************************************************************************/

    function statefulFuzz_assertInvariants() external view {
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
