// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

import { BaseERC20 }             from "../modules/erc20/contracts/BaseERC20.sol";
import { NonTransparentProxied } from "../modules/ntp/contracts/NonTransparentProxied.sol";

import { IMapleToken, IERC20 } from "./interfaces/IMapleToken.sol";

contract MapleToken is IMapleToken, BaseERC20, NonTransparentProxied {

    bytes32 internal constant GLOBALS_SLOT = bytes32(uint256(keccak256("eip1967.proxy.globals")) - 1);

    uint8  public override(BaseERC20, IERC20) decimals = 18;

    string public override(BaseERC20, IERC20) name   = "MPL";
    string public override(BaseERC20, IERC20) symbol = "MPL";

    /**************************************************************************************************************************************/
    /*** View Functions                                                                                                                 ***/
    /**************************************************************************************************************************************/

    function globals() public view override returns (address globals_) {
        globals_ = _getAddress(GLOBALS_SLOT);
    }

}
