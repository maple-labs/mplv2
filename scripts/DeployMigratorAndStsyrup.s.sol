// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.7;

import { console2 as console, Script } from "../modules/forge-std/src/Script.sol";

import { Migrator } from "../modules/migrator/contracts/Migrator.sol";
import { xMPL } from "../modules/xmpl/contracts/xMPL.sol";

// TODO: Double check compute address based on index
contract DeployMigratorAndStsyrup is Script {

    function run() external {
        address ETH_SENDER = vm.envAddress("ETH_SENDER");

        address governor = 0xd6d4Bcde6c816F17889f1Dd3000aF0261B03a196;
        address mplv1    = 0x33349B282065b0284d756F0577FB39c158F935e6;
        address syrup    = computeCreateAddress(ETH_SENDER, 2); // 0x1915A8dE08A92b846dF7C845e140E4b0714820bd;

        vm.startBroadcast(ETH_SENDER);
        address migrator = address(new Migrator(mplv1, syrup));
        console.log("Migrator: %s", migrator);

        address stSyrup = address(new xMPL("StakedSyrup", "stSyrup", governor, syrup, 18));
        console.log("stSyrup: %s", stSyrup);

        vm.stopBroadcast();

    }

}

