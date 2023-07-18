// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.7;

import { console2 as console, Script } from "../modules/forge-std/src/Script.sol";

import { Migrator } from "../modules/migrator/contracts/Migrator.sol";

contract DeployMigrator is Script {

    function run() external {
        address mplv1 = 0x33349B282065b0284d756F0577FB39c158F935e6;
        
        // Derived by using sender 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266 Needs to be computed with correct sender.
        address mplv2 = 0xc1EeD9232A0A44c2463ACB83698c162966FBc78d;

        address ETH_SENDER = vm.envAddress("ETH_SENDER");

        vm.startBroadcast(ETH_SENDER);
        address migrator = address(new Migrator(mplv1, mplv2));
        vm.stopBroadcast();

        console.log("Migrator:", migrator);
    }

}

