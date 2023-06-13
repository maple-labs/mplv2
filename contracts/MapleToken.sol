// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

import { ERC20 }                 from "../modules/erc20/contracts/ERC20.sol";
import { NonTransparentProxied } from "../modules/non-transparent-proxy/contracts/NonTransparentProxied.sol";

contract MapleToken is IMapleToken, ERC20, NonTransparentProxied {

    // TODO: Is this needed?
    address public override globals;

}
