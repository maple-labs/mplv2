// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

import { IMigrator } from "../../modules/migrator/contracts/interfaces/IMigrator.sol";

import { IMapleToken }             from "../../contracts/interfaces/IMapleToken.sol";
import { IMapleTokenProxy }        from "../../contracts/interfaces/IMapleTokenProxy.sol";
import { IRecapitalizationModule } from "../../contracts/interfaces/IRecapitalizationModule.sol";

import { console, Test }            from "../utils/TestBase.sol";
import { IGlobalsLike, IXmplLike }  from "../utils/Interfaces.sol";

import { ProcedureAddressRegistry as AddressRegistry } from "./ProcedureAddressRegistry.sol";

contract ValidationBase is Test, AddressRegistry {

    function setUp() public virtual {
        vm.createSelectFork(vm.envString("ETH_RPC_URL"));
    }

}

contract ValidateDeployContracts is ValidationBase {
    
    function run() external view {
        // Validate initial token state
        IMapleToken token = IMapleToken(mplv2Proxy);
        
        require(token.implementation()         == mplv2Implementation,   "Invalid MapleToken implementation");
        require(token.globals()                == globals,               "Invalid MapleToken globals");
        require(token.governor()               == governor,              "Invalid Governor");
        // require(token.symbol()                 == "MPL",                 "Invalid Symbol"); // TODO hash names for comparison?
        // require(token.name()                   == "Maple Finance Token", "Invalid Name");
        require(token.decimals()               == 18,                    "Invalid Decimals");
        require(token.totalSupply()            == 11_000_000e18,         "Invalid total supply");
        require(token.balanceOf(migrator)      == 10_000_000e18,         "Invalid migrator balance");
        require(token.balanceOf(mapleTreasury) == 1_000_000e18,          "Invalid migrator balance");
        // TODO: check domain hash?

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

        require(globals_.isInstanceOf("RECAPITALIZATION_CLAIMER", recaptalizationClaimer), "Invalid Claimer");
        require(globals_.isValidScheduledCall(
            governor, 
            mplv2Proxy, 
            "MT:ADD_MODULE", 
            abi.encodeWithSelector(IMapleToken.addModule.selector, recaptalizationClaimer)), "Invalid Call"
        );

        //  Check xMPL
        IXmplLike xmpl_ = IXmplLike(xmpl);

        require(xmpl_.scheduledMigrator() == migrator, "Invalid migrator");
        require(xmpl_.scheduledNewAsset() == mplv2Proxy, "Invalid new asset");
        // TODO assert the timestamp?

        // NOTE: can't check recap module because call is just made to globals
    }
}
