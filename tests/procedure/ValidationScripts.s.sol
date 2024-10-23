// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

import { IMigrator } from "../../modules/migrator/contracts/interfaces/IMigrator.sol";

import { IXmplLike } from "tests/utils/Interfaces.sol";

import { IMapleToken }             from "../../contracts/interfaces/IMapleToken.sol";
import { IRecapitalizationModule } from "../../contracts/interfaces/IRecapitalizationModule.sol";

import { console, Test } from "../utils/TestBase.sol";
import { IGlobalsLike }  from "../utils/Interfaces.sol";

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
        // Validate initial token state
        IMapleToken token = IMapleToken(mplv2Proxy);

        require(token.implementation()         == mplv2Implementation, "Invalid MapleToken implementation");
        require(token.globals()                == globals,             "Invalid MapleToken globals");
        require(token.governor()               == governor,            "Invalid Governor");
        require(token.decimals()               == 18,                  "Invalid Decimals");
        require(token.totalSupply()            == 1_154_930_098e18,    "Invalid total supply");
        require(token.balanceOf(migrator)      == 1_000_000_000e18,    "Invalid migrator balance");
        require(token.balanceOf(mapleTreasury) == 154_930_098e18,      "Invalid migrator balance");

        require(keccak256(abi.encode(token.symbol())) == keccak256(abi.encode("SYRUP")),       "Invalid Symbol");
        require(keccak256(abi.encode(token.name()))   == keccak256(abi.encode("Syrup Token")), "Invalid Name");

        // Validate Migrator
        require(IMigrator(migrator).oldToken()         == mpl,        "Invalid old token");
        require(IMigrator(migrator).newToken()         == mplv2Proxy, "Invalid new token");
        require(IMigrator(migrator).tokenSplitScalar() == 100,        "Invalid Scalar");

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

        // Validate xMPL
        IXmplLike stakedToken = IXmplLike(stSyrup);
        // assert constructor args
        require(keccak256(abi.encode(stakedToken.name()))   == keccak256(abi.encode("Staked Syrup")), "Invalid Name");
        require(keccak256(abi.encode(stakedToken.symbol())) == keccak256(abi.encode("stSYRUP")),      "Invalid Symbol");
        require(stakedToken.owner()                         == governor,                              "Invalid Owner");
        require(stakedToken.asset()                         == mplv2Proxy,                            "Invalid Asset");
        require(stakedToken.precision()                     == 18,                                    "Invalid Precision");
    }

}

contract ValidateSetup is ValidationBase {

    function run() external view {
        // Check globals
        IGlobalsLike globals_ = IGlobalsLike(globals);

        require(globals_.isInstanceOf("RECAPITALIZATION_CLAIMER", recapitalizationClaimer), "Invalid Claimer");

        (uint256 timestamp, bytes32 dataHash) = globals_.scheduledCalls(
            governor,
            mplv2Proxy,
            "MT:ADD_MODULE");

        require(timestamp <= block.timestamp && timestamp != 0, "not scheduled 1");
        require(dataHash == keccak256(abi.encode(
            abi.encodeWithSelector(IMapleToken.addModule.selector, recapitalizationModule))),
            "Invalid data hash 1"
        );

        uint32[] memory timestamps = new uint32[](3);
        timestamps[0] = uint32(1727755200);  // October 1st 00:00 2024 EST
        timestamps[1] = uint32(1735704000);  // January 1st 00:00 2025 EST
        timestamps[2] = uint32(1767240000);  // January 1st 00:00 2026 EST

        uint208[] memory issuanceRates = new uint208[](3);
        issuanceRates[0] = 1792295944041868000;
        issuanceRates[1] = 1888765220700152300;
        issuanceRates[2] = 0;

        (timestamp, dataHash) = globals_.scheduledCalls(
            governor,
            recapitalizationModule,
            "RM:SCHEDULE");

        require(timestamp <= block.timestamp && timestamp != 0, "not scheduled 2");
        require(dataHash == keccak256(abi.encode(
            abi.encodeWithSelector(IRecapitalizationModule.schedule.selector, timestamps, issuanceRates))),
            "Invalid data hash 2"
        );
    }
}

contract ValidateAddModule is ValidationBase {

    function run() external view {
        console.log(block.timestamp);
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
        require(module.lastScheduledWindowId() == 3, "Invalid lastScheduledWindowId");

        (uint16 nextWindowId, uint32 windowStart, uint208 issuanceRate) = module.windows(1);

        require(nextWindowId == 2,                   "Invalid nextWindowId 1");
        require(windowStart  == 1727755200,          "Invalid windowStart 1");
        require(issuanceRate == 1792295944041868000, "Invalid issuanceRate 1");

        (nextWindowId, windowStart, issuanceRate) = module.windows(2);

        require(nextWindowId == 3,                   "Invalid nextWindowId 2");
        require(windowStart  == 1735704000,          "Invalid windowStart 2");
        require(issuanceRate == 1888765220700152300, "Invalid issuanceRate 2");

        (nextWindowId, windowStart, issuanceRate) = module.windows(3);

        require(nextWindowId == 0,          "Invalid nextWindowId 3");
        require(windowStart  == 1767240000, "Invalid windowStart 3");
        require(issuanceRate == 0,          "Invalid issuanceRate 3");
    }

}
