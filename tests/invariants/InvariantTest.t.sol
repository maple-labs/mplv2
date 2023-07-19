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

import { DistributionHandler } from "./DistributionHandler.sol";
import { ModuleHandler }       from "./ModuleHandler.sol";
import { ModuleInvariants }    from "./ModuleInvariants.sol";

contract InvariantTest is ModuleInvariants {

    address claimer  = makeAddr("claimer");
    address governor = makeAddr("governor");
    address migrator = makeAddr("migrator");
    address treasury = makeAddr("treasury");

    IGlobalsLike mapleGlobals;
    IMapleToken  mapleToken;

    IEmergencyModule emergencyModule;
    IInflationModule inflationModule;

    DistributionHandler distributionHandler;
    ModuleHandler       moduleHandler;

    function setUp() external {
        deployContracts();
        configureContracts();
        setupHandlers();
    }

    function deployContracts() internal {
        mapleGlobals = IGlobalsLike(address(new NonTransparentProxy(governor, deployGlobals())));
        mapleToken   = IMapleToken(address(new MapleTokenProxy(
            address(mapleGlobals),
            address(new MapleToken()),
            address(new MapleTokenInitializer()),
            migrator
        )));

        emergencyModule = new EmergencyModule(address(mapleGlobals), address(mapleToken));
        inflationModule = new InflationModule(address(mapleToken));
    }

    function configureContracts() internal {
        vm.startPrank(governor);

        mapleGlobals.setMapleTreasury(treasury);
        mapleGlobals.setValidInstanceOf("INFLATION_CLAIMER", claimer, true);

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

    function setupHandlers() internal {
        bytes4[] memory selectors = new bytes4[](5);

        selectors[0] = ModuleHandler.warp.selector;
        selectors[1] = ModuleHandler.claim.selector;
        selectors[2] = ModuleHandler.schedule.selector;
        selectors[3] = ModuleHandler.emergencyMint.selector;
        selectors[4] = ModuleHandler.emergencyBurn.selector;

        uint256[] memory weights = new uint256[](5);

        weights[0] = 120;
        weights[1] = 60;
        weights[2] = 10;
        weights[3] = 5;
        weights[4] = 5;

        moduleHandler       = new ModuleHandler(mapleGlobals, mapleToken, emergencyModule, inflationModule, claimer);
        distributionHandler = new DistributionHandler(address(moduleHandler), selectors, weights);

        targetContract(address(distributionHandler));
    }

    /**************************************************************************************************************************************/
    /*** Invariant Tests                                                                                                                ***/
    /**************************************************************************************************************************************/

    function statefulFuzz_assertInvariants() external {
        assert_inflationModule_invariant_A(inflationModule);
        assert_inflationModule_invariant_B(inflationModule);
        assert_inflationModule_invariant_C(inflationModule);
        assert_inflationModule_invariant_D(inflationModule);
        assert_inflationModule_invariant_E(inflationModule);
        assert_inflationModule_invariant_F(inflationModule);
        assert_inflationModule_invariant_G(inflationModule);
        assert_inflationModule_invariant_H(inflationModule, moduleHandler.blockTimestamp());
        assert_inflationModule_invariant_I(inflationModule);
    }

}
