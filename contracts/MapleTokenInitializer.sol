// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

import { ERC20Proxied }          from "../modules/erc20/contracts/ERC20Proxied.sol";
import { NonTransparentProxied } from "../modules/ntp/contracts/NonTransparentProxied.sol";

contract MapleTokenInitializer is ERC20Proxied, NonTransparentProxied {

    function initialize(address migrator_, address treasury_) external {
        name     = "Maple Finance";
        symbol   = "MPL";
        decimals = 18;

        _mint(migrator_, 10_000_000e18);
        _mint(treasury_, 1_000_000e18);
    }

}
