// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

import { console2 as console, Script } from "../modules/forge-std/src/Script.sol";

import { MapleToken }            from "../contracts/MapleToken.sol";
import { MapleTokenInitializer } from "../contracts/MapleTokenInitializer.sol";
import { MapleTokenProxy }       from "../contracts/MapleTokenProxy.sol";

contract DeployToken is Script {

    function run() external {
        address ETH_SENDER = vm.envAddress("ETH_SENDER");

        address mapleGlobals = 0x804a6F5F667170F545Bf14e5DDB48C70B788390C;

        // Derived by using sender 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266. Needs to be computed with correct sender.
        address migrator = 0xce830DA8667097BB491A70da268b76a081211814;

        vm.startBroadcast(ETH_SENDER);

        address tokenImplementation = address(new MapleToken());
        address tokenInitializer    = address(new MapleTokenInitializer());

        console.log("Token Implementation: %s", tokenImplementation);
        console.log("Token Initializer:    %s", tokenInitializer);

        address tokenProxy = address(new MapleTokenProxy(mapleGlobals, tokenImplementation, tokenInitializer, migrator));

        console.log("Token Proxy:          %s", tokenProxy);

        vm.stopBroadcast();
    }

}
