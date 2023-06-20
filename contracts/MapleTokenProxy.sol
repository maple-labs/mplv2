// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

import { NonTransparentProxy } from "../modules/ntp/contracts/NonTransparentProxy.sol";

import { IGlobalsLike } from "./interfaces/Interfaces.sol";

contract MapleTokenProxy is NonTransparentProxy {

    bytes32 internal constant GLOBALS_SLOT = bytes32(uint256(keccak256("eip1967.proxy.globals")) - 1);

    constructor(address admin_, address implementation_, address globals_) NonTransparentProxy(admin_, implementation_) {
        _setAddress(GLOBALS_SLOT, globals_);
    }

    /**************************************************************************************************************************************/
    /*** Overridden Functions                                                                                                           ***/
    /**************************************************************************************************************************************/

    function setImplementation(address newImplementation_) override external {
        IGlobalsLike globals_ = IGlobalsLike(globals());
        bool isScheduledCall_ = globals_.isValidScheduledCall(msg.sender, address(this), "MTP:SET_IMPLEMENTATION", msg.data);

        require(msg.sender == _admin(), "MTP:SI:NOT_ADMIN");
        require(isScheduledCall_,       "MTP:SI:NOT_SCHEDULED");

        globals_.unscheduleCall(msg.sender, address(this), "MTP:SET_IMPLEMENTATION", msg.data);

        _setAddress(IMPLEMENTATION_SLOT, newImplementation_);
    }

    /**************************************************************************************************************************************/
    /*** Utility Functions                                                                                                              ***/
    /**************************************************************************************************************************************/

    function globals() private view returns (address globals_) {
        globals_ = _getAddress(GLOBALS_SLOT);
    }

}
