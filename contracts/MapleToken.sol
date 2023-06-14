// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

import { ERC20 }                 from "../modules/erc20/contracts/ERC20.sol";
import { NonTransparentProxied } from "../modules/ntp/contracts/NonTransparentProxied.sol";

import { IMapleToken } from "./interfaces/IMapleToken.sol";

abstract contract MapleToken is IMapleToken, ERC20, NonTransparentProxied { }
