// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

import { IMigrator } from "../../modules/migrator/contracts/interfaces/IMigrator.sol";

import { NonTransparentProxy } from "../../modules/ntp/contracts/NonTransparentProxy.sol";

import { IMapleToken }      from "../../contracts/interfaces/IMapleToken.sol";
import { IEmergencyModule } from "../../contracts/interfaces/IEmergencyModule.sol";
import { IInflationModule } from "../../contracts/interfaces/IInflationModule.sol";

import { EmergencyModule }       from "../../contracts/EmergencyModule.sol";
import { InflationModule }       from "../../contracts/InflationModule.sol";
import { MapleToken }            from "../../contracts/MapleToken.sol";
import { MapleTokenInitializer } from "../../contracts/MapleTokenInitializer.sol";
import { MapleTokenProxy }       from "../../contracts/MapleTokenProxy.sol";

import { DistributionHandler } from "../invariants/DistributionHandler.sol";
import { ModuleHandler }       from "../invariants/ModuleHandler.sol";
import { ModuleInvariants }    from "../invariants/ModuleInvariants.sol";

import { IGlobalsLike, IXmplLike } from "../utils/Interfaces.sol";
import { console }                 from "../utils/TestBase.sol";

contract xMPLMigration is ModuleInvariants {

    uint256 constant OLD_SUPPLY    = 10_000_000e18;
    uint256 constant ACTIONS_COUNT = 20;

    address constant XMPL      = 0x4937A209D4cDbD3ecD48857277cfd4dA4D82914c;
    address constant OLD_TOKEN = 0x33349B282065b0284d756F0577FB39c158F935e6;

    address claimer         = makeAddr("claimer");
    address governor        = makeAddr("governor");
    address migratorAddress = makeAddr("migrator");
    address treasury        = makeAddr("treasury");

    uint256 start;

    IGlobalsLike     globals;
    IMapleToken      token;
    IMigrator        migrator;
    IEmergencyModule emergencyModule;
    IInflationModule inflationModule;

    DistributionHandler distributionHandler;
    ModuleHandler       moduleHandler;

    IMapleToken oldToken = IMapleToken(OLD_TOKEN);
    IXmplLike   xmpl     = IXmplLike(XMPL);

    function setUp() public virtual {
        vm.createSelectFork(vm.envString("ETH_RPC_URL"), 17622100);

        globals  = IGlobalsLike(address(new NonTransparentProxy(governor, deployGlobals())));
        token    = IMapleToken(address(new MapleTokenProxy(address(globals), address(new MapleToken()), address(new MapleTokenInitializer()), migratorAddress)));
        migrator = IMigrator(deployMigrator(address(oldToken), address(token)));

        emergencyModule = new EmergencyModule(address(globals), address(token));
        inflationModule = new InflationModule(address(token));

        configureContracts();
        setupHandlers();

        start = block.timestamp;
    }

    function test_e2e_lifecycle(uint256 seed) external {
        migrateXmpl();

        // Perform some actions before asserting the invariants
        for (uint i = 0; i < ACTIONS_COUNT; i++) {
            distributionHandler.entryPoint(uint256(keccak256(abi.encode(seed, i, "weight"))), uint256(keccak256(abi.encode(seed, i))));
        }

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

    /**************************************************************************************************************************************/
    /*** Helper Functions                                                                                                               ***/
    /**************************************************************************************************************************************/

    function migrateXmpl() internal {
        address owner = xmpl.owner();
        // Schedule migration on xMPL contract
        vm.prank(owner);
        xmpl.scheduleMigration(address(migrator), address(token));

        vm.warp(start + 864000 + 1 seconds);
        
        vm.prank(owner);
        xmpl.performMigration();
    }

    function deployMigrator(address oldToken_, address newToken_) internal returns (address migratorAddress_) {
        address deployedAddress = deployCode("Migrator.sol", abi.encode(oldToken_, newToken_));
        migratorAddress_ = migratorAddress;

        // Using etch to always get a deterministic address for the migrator
        vm.etch(migratorAddress_, deployedAddress.code);
    }

    function configureContracts() internal {
        vm.startPrank(governor);

        globals.setMapleTreasury(treasury);
        globals.setValidInstanceOf("INFLATION_CLAIMER", claimer, true);

        globals.scheduleCall(
            address(token),
            "MT:ADD_MODULE",
            abi.encodeWithSelector(IMapleToken.addModule.selector, address(emergencyModule))
        );

        token.addModule(address(emergencyModule));

        globals.scheduleCall(
            address(token),
            "MT:ADD_MODULE",
            abi.encodeWithSelector(IMapleToken.addModule.selector, address(inflationModule))
        );

        token.addModule(address(inflationModule));

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

        moduleHandler       = new ModuleHandler(globals, token, emergencyModule, inflationModule, claimer);
        distributionHandler = new DistributionHandler(address(moduleHandler), selectors, weights);
    }

}
