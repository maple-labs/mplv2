// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

import { NonTransparentProxy } from "../modules/ntp/contracts/NonTransparentProxy.sol";

contract MapleTokenProxy is NonTransparentProxy {

    bytes32 internal constant GLOBALS_SLOT = bytes32(uint256(keccak256("eip1967.proxy.globals")) - 1);

    constructor(address admin_, address implementation_, address globals_) NonTransparentProxy(admin_, implementation_) {
        _setAddress(GLOBALS_SLOT, globals_);
    }

    /**************************************************************************************************************************************/
    /*** Overridden Functions                                                                                                           ***/
    /**************************************************************************************************************************************/

    function setImplementation(address newImplementation_) override external {
        // TODO: Check globals for scheduled call
        require(msg.sender == _admin(), "NTP:SI:NOT_ADMIN");
        _setAddress(IMPLEMENTATION_SLOT, newImplementation_);
    }

}
