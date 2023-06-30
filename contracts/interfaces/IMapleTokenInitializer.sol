// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

import { IERC20 }                 from "../../modules/erc20/contracts/interfaces/IERC20.sol";
import { INonTransparentProxied } from "../../modules/ntp/contracts/interfaces/INonTransparentProxied.sol";

interface IMapleTokenInitializer is IERC20, INonTransparentProxied {
    /**
        @dev    Contract was initialixed
        @param  migrator Address of the Maple migrator contract.
        @param  treasury Address of the Maple treasury contract.
    **/    
    event Initialized(address migrator, address treasury);

    /**
        @dev    Initializes MapleToken state.
        @param  migrator Address of the Maple migrator contract.
        @param  treasury Address of the Maple treasury contract.
    **/
    function initialize(address migrator, address treasury) external;

}
