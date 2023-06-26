// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

import { IERC20 }                 from "../../modules/erc20/contracts/interfaces/IERC20.sol";
import { INonTransparentProxied } from "../../modules/ntp/contracts/interfaces/INonTransparentProxied.sol";

interface IMapleToken is IERC20, INonTransparentProxied {

    /**
     *  @dev    Returns the address of the Maple Globals contract.
     *  @return globals The address of the Maple Globals contract.
     */
    function globals() external view returns (address globals);

}
