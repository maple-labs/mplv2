// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

interface IEmergencyModule {

    /**************************************************************************************************************************************/
    /*** Events                                                                                                                         ***/
    /**************************************************************************************************************************************/
    // Note: those are exactly the same as a the events on the ERC20. Should we even are to emit?
    /**
     *  @dev   A burn was performed.
     *  @param from   The address of the account whose tokens were burned.
     *  @param amount The amount of tokens that were burned.
     */
    event Burn(address indexed from, uint256 amount);

    /**
     *  @dev   A mint was performed.
     *  @param to     The address of the account whose tokens were minted.
     *  @param amount The amount of tokens that were minted.
     */
    event Mint(address indexed to, uint256 amount);

    /**************************************************************************************************************************************/
    /*** Functions                                                                                                                      ***/
    /**************************************************************************************************************************************/

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
    function globals() external view returns(address globals);

    /**
     *  @dev   Mints a specified amount of tokens to the Maple treasury.
     *  @param amount The amount of tokens to mint.
     */
    function mint(uint256 amount) external;

    /**
     *  @dev    Returns the address of the Maple treasury.
     *  @return token The address of the underlying token being managed.
     */
    function token() external view returns(address token);

}
