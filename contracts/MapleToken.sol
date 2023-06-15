// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

import { ERC20 }               from "../modules/erc20/contracts/ERC20.sol";
import { NonTransparentProxied } from "../modules/ntp/contracts/NonTransparentProxied.sol";

import { IMapleToken } from "./interfaces/IMapleToken.sol";

contract MapleToken is IMapleToken, ERC20, NonTransparentProxied {

    bytes32 internal constant GLOBALS_SLOT = bytes32(uint256(keccak256("eip1967.proxy.globals")) - 1);

    constructor(string memory name_, string memory symbol_, uint8 decimals_) ERC20(name_, symbol_, decimals_) { }

    /**************************************************************************************************************************************/
    /*** View Functions                                                                                                                 ***/
    /**************************************************************************************************************************************/

    function globals() public view override returns (address globals_) {
        globals_ = _getAddress(GLOBALS_SLOT);
    }

}
