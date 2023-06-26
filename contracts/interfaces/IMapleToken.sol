// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

import { IERC20 }                 from "../../modules/erc20/contracts/interfaces/IERC20.sol";
import { INonTransparentProxied } from "../../modules/ntp/contracts/interfaces/INonTransparentProxied.sol";

interface IMapleToken is IERC20, INonTransparentProxied {

    /**
     *  @dev    Adds a new module to the MapleToken.
     *  @param module The address the module to add.
     *  @param burner Whether or not the module can burn tokens.
     *  @param minter Whether or not the module can mint tokens.
     */    
    function addModule(address module, bool burner, bool minter) external;

    /**
     *  @dev    Burns a specified amount of tokens from the an account.
     *  @param from_ The address to burn tokens from.
     *  @param amount_ The amount of tokens to burn.
     */
    function burn(address from_, uint256 amount_) external;

    /**
     *  @dev    Returns the address of the Maple Globals contract.
     *  @return globals The address of the Maple Globals contract.
     */
    function globals() external view returns (address globals);

    /**
     *  @dev    Returns true if the specified module is a burner.
     *  @param  module The address of the module to check.
     *  @return isBurner True if the module is a burner, false otherwise.
     */
    function isBurner(address module) external view returns (bool isBurner);

    /**
     *  @dev    Returns true if the specified module is a minter.
     *  @param  module The address of the module to check.
     *  @return isMinter True if the module is a minter, false otherwise.
     */
    function isMinter(address module) external view returns (bool isMinter);

    /**
     *  @dev   Mints a specified amount of tokens to an account.
     *  @param to_ The address to mint tokens to.
     *  @param amount_ The amount of tokens to mint.
     */
    function mint(address to_, uint256 amount_) external;

    /**
     *  @dev   Removes a module from the MapleToken.
     *  @param module The address the module to remove.
     */
    function removeModule(address module) external;

}
