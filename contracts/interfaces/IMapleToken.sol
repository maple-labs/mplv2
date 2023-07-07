// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

import { IERC20 }                 from "../../modules/erc20/contracts/interfaces/IERC20.sol";
import { INonTransparentProxied } from "../../modules/ntp/contracts/interfaces/INonTransparentProxied.sol";

interface IMapleToken is IERC20, INonTransparentProxied {

    /**************************************************************************************************************************************/
    /*** Events                                                                                                                         ***/
    /**************************************************************************************************************************************/

    /**
     *  @dev   A new module was added to the MapleToken.
     *  @param module The address the module added.
     */ 
    event ModuleAdded(address indexed module);

    /**
     *  @dev   A module was removed from the MapleToken.
     *  @param module The address the module removed.
     */
    event ModuleRemoved(address indexed module);

    /**************************************************************************************************************************************/
    /*** Functions                                                                                                                      ***/
    /**************************************************************************************************************************************/

    /**
     *  @dev   Adds a new module to the MapleToken.
     *  @param module  The address the module to add.
     */    
    function addModule(address module) external;

    /**
     *  @dev   Burns a specified amount of tokens from the an account.
     *  @param from   The address to burn tokens from.
     *  @param amount The amount of tokens to burn.
     */
    function burn(address from, uint256 amount) external;

    /**
     *  @dev    Returns the address of the Maple Globals contract.
     *  @return globals The address of the Maple Globals contract.
     */
    function globals() external view returns (address globals);

    /**
     *  @dev    Returns true if the specified address is module.
     *  @param  module The address of the module to check.
     *  @return isModule True if the address is a valid module.
     */
    function isModule(address module) external view returns (bool isModule);

    /**
     *  @dev   Mints a specified amount of tokens to an account.
     *  @param to     The address to mint tokens to.
     *  @param amount The amount of tokens to mint.
     */
    function mint(address to, uint256 amount) external;

    /**
     *  @dev   Removes a module from the MapleToken.
     *  @param module The address the module to remove.
     */
    function removeModule(address module) external;

}
