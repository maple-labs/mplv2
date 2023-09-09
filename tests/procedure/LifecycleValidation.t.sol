// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

import { IMigrator } from "../../modules/migrator/contracts/interfaces/IMigrator.sol";

import { IEmergencyModule }        from "../../contracts/interfaces/IEmergencyModule.sol";
import { IMapleToken }             from "../../contracts/interfaces/IMapleToken.sol";
import { IRecapitalizationModule } from "../../contracts/interfaces/IRecapitalizationModule.sol";

import { EmergencyModule }        from "../../contracts/EmergencyModule.sol";
import { MapleToken }             from "../../contracts/MapleToken.sol";
import { MapleTokenInitializer }  from "../../contracts/MapleTokenInitializer.sol";
import { MapleTokenProxy }        from "../../contracts/MapleTokenProxy.sol";
import { RecapitalizationModule } from "../../contracts/RecapitalizationModule.sol";

import { RecapitalizationModuleHealthChecker } from "../health-checkers/RecapitalizationModuleHealthChecker.sol";

import { DistributionHandler } from "../invariants/DistributionHandler.sol";
import { ModuleHandler }       from "../invariants/ModuleHandler.sol";
import { ModuleInvariants }    from "../invariants/ModuleInvariants.sol";

import { IGlobalsLike, IXmplLike } from "../utils/Interfaces.sol";
import { console }                 from "../utils/TestBase.sol";

import { LifecycleBase } from "../e2e/MigrationAndLifecycle.t.sol";
import { ProcedureAddressRegistry as AddressRegistry } from "./ProcedureAddressRegistry.sol";

contract LifecycleValidation is LifecycleBase, AddressRegistry {

    function setUp() public virtual {
        vm.createSelectFork(vm.envString("ETH_RPC_URL"));

        _globals                = IGlobalsLike(globals);
        _token                  = IMapleToken(mplv2Proxy);
        _migrator               = IMigrator(migrator);
        _recapitalizationModule = RecapitalizationModule(recapitalizationModule);
        _emergencyModule        = new EmergencyModule(address(_globals), address(_token));

        claimer_         = securityAdmin;
        governor_        = governor;
        migratorAddress  = migrator;
        treasury_        = mapleTreasury;

        healthChecker = new RecapitalizationModuleHealthChecker();

        // Since the procedure doesn't do that, add emergency module
        vm.prank(governor);
        _globals.scheduleCall(
            address(_token),
            "MT:ADD_MODULE",
            abi.encodeWithSelector(IMapleToken.addModule.selector, address(_emergencyModule))
        );

        vm.warp(block.timestamp + 7 days + 1);
        vm.prank(governor);
        _token.addModule(address(_emergencyModule));

        setupHandlers();
    }

    function test_lifecycleValidation(uint256 seed) external{
        runLifecycle(seed);
    }

}
