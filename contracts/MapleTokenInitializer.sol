// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

import { ERC20Proxied }          from "../modules/erc20/contracts/ERC20Proxied.sol";
import { NonTransparentProxied } from "../modules/ntp/contracts/NonTransparentProxied.sol";

import { IGlobalsLike } from "./interfaces/Interfaces.sol";

contract MapleTokenInitializer is ERC20Proxied, NonTransparentProxied {

    bytes32 constant GLOBALS_SLOT = bytes32(uint256(keccak256("eip1967.proxy.globals")) - 1);

    fallback() external {
        name     = "Maple Finance";
        symbol   = "MPL";
        decimals = 18;

        address treasury_ = IGlobalsLike(_getAddress(GLOBALS_SLOT)).mapleTreasury();

        _mint(treasury_, 1_000_000e18);
    }

}
