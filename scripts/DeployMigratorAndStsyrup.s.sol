// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.7;

import { console2 as console, Script } from "../modules/forge-std/src/Script.sol";

import { Migrator } from "../modules/migrator/contracts/Migrator.sol";
import { xMPL }     from "../modules/xmpl/contracts/xMPL.sol";

contract DeployMigratorAndStsyrup is Script {

    function run() external {
        address ETH_SENDER = vm.envAddress("ETH_SENDER");

        address governor = 0xd6d4Bcde6c816F17889f1Dd3000aF0261B03a196;
        address mplv1    = 0x33349B282065b0284d756F0577FB39c158F935e6;
        address globals  = 0x804a6F5F667170F545Bf14e5DDB48C70B788390C;
        address syrup    = computeCreateAddress(ETH_SENDER, 2);  // 0x643C4E15d7d62Ad0aBeC4a9BD4b001aA3Ef52d66

        vm.startBroadcast(ETH_SENDER);
        address migrator = address(new Migrator(globals, mplv1, syrup, 100));
        console.log("Migrator: %s", migrator);

        address stSyrup = address(new xMPL("Staked Syrup", "stSYRUP", governor, syrup, 18));
        console.log("stSYRUP: %s", stSyrup);

        vm.stopBroadcast();

    }

}

