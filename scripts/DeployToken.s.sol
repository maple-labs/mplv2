// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

import { console2 as console, Script } from "../modules/forge-std/src/Script.sol";

import { MapleToken }             from "../contracts/MapleToken.sol";
import { MapleTokenInitializer }  from "../contracts/MapleTokenInitializer.sol";
import { MapleTokenProxy }        from "../contracts/MapleTokenProxy.sol";
import { RecapitalizationModule } from "../contracts/RecapitalizationModule.sol";

contract DeployToken is Script {

    function run() external {
        address ETH_SENDER = vm.envAddress("ETH_SENDER");

        address mapleGlobals = 0x804a6F5F667170F545Bf14e5DDB48C70B788390C;
        address migrator     = computeCreateAddress(ETH_SENDER, 4);  // 0x9c9499edD0cd2dCBc3C9Dd5070bAf54777AD8F2C

        vm.startBroadcast(ETH_SENDER);

        address tokenImplementation = address(new MapleToken());
        address tokenInitializer    = address(new MapleTokenInitializer());

        console.log("Token Implementation:    %s", tokenImplementation);
        console.log("Token Initializer:       %s", tokenInitializer);

        address tokenProxy = address(new MapleTokenProxy(mapleGlobals, tokenImplementation, tokenInitializer, migrator));

        console.log("Token Proxy:             %s", tokenProxy);

        address recapitalizationModule = address(new RecapitalizationModule(tokenProxy));

        console.log("Recapitalization Module: %s", recapitalizationModule);

        vm.stopBroadcast();
    }

}
