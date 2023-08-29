// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

import { IMigrator } from "../../modules/migrator/contracts/interfaces/IMigrator.sol";

import { IMapleToken }             from "../../contracts/interfaces/IMapleToken.sol";
import { IRecapitalizationModule } from "../../contracts/interfaces/IRecapitalizationModule.sol";

import { console, Test }            from "../utils/TestBase.sol";
import { IGlobalsLike, IXmplLike }  from "../utils/Interfaces.sol";

import { ProcedureAddressRegistry as AddressRegistry } from "./ProcedureAddressRegistry.sol";

contract ValidationBase is Test, AddressRegistry {

    function setUp() public virtual {
        vm.createSelectFork(vm.envString("ETH_RPC_URL"));
    }

    function validateCodeHash(address account, bytes32 codeHash) internal view {
        console.log("computed code hash:", uint256(account.codehash));
        console.log("expected code hash:", uint256(codeHash));

        require(account.codehash == codeHash, "code hash does not match");
    }

}

contract ValidateDeployContracts is ValidationBase {

    function run() external view {
        // Validate code hashse
        // validateCodeHash(mplv2Implementation,    0x0);
        // validateCodeHash(mplv2Proxy,             0x0);
        // validateCodeHash(mplv2Initializer,       0x0);
        // validateCodeHash(recapitalizationModule, 0x0);
        // validateCodeHash(migrator,               0x0);

        // Validate initial token state
        IMapleToken token = IMapleToken(mplv2Proxy);

        require(token.implementation()         == mplv2Implementation,   "Invalid MapleToken implementation");
        require(token.globals()                == globals,               "Invalid MapleToken globals");
        require(token.governor()               == governor,              "Invalid Governor");
        require(token.decimals()               == 18,                    "Invalid Decimals");
        require(token.totalSupply()            == 11_000_000e18,         "Invalid total supply");
        require(token.balanceOf(migrator)      == 10_000_000e18,         "Invalid migrator balance");
        require(token.balanceOf(mapleTreasury) == 1_000_000e18,          "Invalid migrator balance");

        require(keccak256(abi.encode(token.symbol())) == keccak256(abi.encode("MPL")),         "Invalid Symbol");
        require(keccak256(abi.encode(token.name()))   == keccak256(abi.encode("Maple Token")), "Invalid Name");

        // Validate Migrator
        require(IMigrator(migrator).oldToken() == mpl,        "Invalid old token");
        require(IMigrator(migrator).newToken() == mplv2Proxy, "Invalid new token");

        // Validate RecapitalizationModule
        IRecapitalizationModule recapitalizationModule_ = IRecapitalizationModule(recapitalizationModule);

        require(recapitalizationModule_.token() == mplv2Proxy, "Invalid token");

        require(recapitalizationModule_.claimable(uint32(block.timestamp)) == 0, "Invalid Claimable");
        require(recapitalizationModule_.currentIssuanceRate()              == 0, "Invalid IR");
        require(recapitalizationModule_.currentWindowId()                  == 0, "Invalid currentWindowId");
        require(recapitalizationModule_.currentWindowStart()               == 0, "Invalid currentWindowStart");
        require(recapitalizationModule_.lastClaimedTimestamp()             == 0, "Invalid lastClaimedTimestamp");
        require(recapitalizationModule_.lastClaimedWindowId()              == 0, "Invalid lastClaimedWindowId");
        require(recapitalizationModule_.lastScheduledWindowId()            == 0, "Invalid lastScheduledWindowId");
    }

}

contract ValidateSetup is ValidationBase {

    function run() external view {
        // Check globals
        IGlobalsLike globals_ = IGlobalsLike(globals);

        require(globals_.isInstanceOf("RECAPITALIZATION_CLAIMER", recapitalizationClaimer), "Invalid Claimer");

        require(globals_.isValidScheduledCall(
            governor,
            mplv2Proxy,
            "MT:ADD_MODULE",
            abi.encodeWithSelector(IMapleToken.addModule.selector, recapitalizationModule)), "Invalid Call"
        );

        uint32[] memory timestamps = new uint32[](4);
        timestamps[0] = uint32(1696132800);  // October 1st 00:00 2023 EST
        timestamps[1] = uint32(1704081600);  // January 1st 00:00 2024 EST
        timestamps[2] = uint32(1735704000);  // January 1st 00:00 2025 EST
        timestamps[3] = uint32(1767240000);  // January 1st 00:00 2026 EST

        uint208[] memory issuanceRates = new uint208[](4);
        issuanceRates[0] = 15725644122383252;
        issuanceRates[1] = 17922959674155030;
        issuanceRates[2] = 18887652207001524;
        issuanceRates[3] = 0;

        require(globals_.isValidScheduledCall(
            governor,
            recapitalizationModule,
            "RM:SCHEDULE",
            abi.encodeWithSelector(IRecapitalizationModule.schedule.selector, timestamps, issuanceRates)), "Invalid Call"
        );

        //  Check xMPL
        IXmplLike xmpl_ = IXmplLike(xmpl);

        require(xmpl_.scheduledMigrator()           == migrator,                  "Invalid migrator");
        require(xmpl_.scheduledNewAsset()           == mplv2Proxy,                "Invalid new asset");
        require(xmpl_.scheduledMigrationTimestamp() <= block.timestamp + 10 days, "Invalid timestamp");
    }
}

contract ValidateAddModule is ValidationBase {

    function run() external view {
        // Verify module was added
        require(IMapleToken(mplv2Proxy).isModule(recapitalizationModule), "Module not added");

        // Verify call was unscheduled
        require(!IGlobalsLike(globals).isValidScheduledCall(
            governor,
            mplv2Proxy,
            "MT:ADD_MODULE",
            abi.encodeWithSelector(IMapleToken.addModule.selector, recapitalizationClaimer)), "Call not unscheduled"
        );

        // Verify Recap module was scheduled properly
        IRecapitalizationModule module = IRecapitalizationModule(recapitalizationModule);

        require(module.currentWindowId()       == 0, "Invalid currentWindowId");
        require(module.lastScheduledWindowId() == 1, "Invalid lastScheduledWindowId");

        (uint16 nextWindowId, uint32 windowStart, uint208 issuanceRate) = module.windows(1);

        require(nextWindowId == 0,                 "Invalid nextWindowId");
        require(windowStart  == 1696132800,        "Invalid windowStart");
        require(issuanceRate == 17440385591070524, "Invalid issuanceRate");

        require(module.claimable(uint32(1727755200)) == 1_100_000e18, "Invalid claimable at year mark");
    }

}

contract ValidateMigrateXmpl is ValidationBase {

    function run() external view {
        IXmplLike xmpl_ = IXmplLike(xmpl);

        // Verify xMPL was migrated
        require(xmpl_.asset()                       == mplv2Proxy, "xMPL not migrated");
        require(xmpl_.scheduledMigrator()           == address(0), "Invalid migrator");
        require(xmpl_.scheduledNewAsset()           == address(0), "Invalid new asset");
        require(xmpl_.scheduledMigrationTimestamp() == 0,          "Invalid timestamp");

        // Verify call was unscheduled
        require(!IGlobalsLike(globals).isValidScheduledCall(
            governor,
            xmpl,
            "XMPL:MIGRATE",
            abi.encodeWithSelector(IXmplLike.performMigration.selector)), "Call not unscheduled"
        );
    }

}
