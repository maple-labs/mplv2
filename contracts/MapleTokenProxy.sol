// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

import { NonTransparentProxy } from "../modules/ntp/contracts/NonTransparentProxy.sol";

import { IMapleTokenInitializerLike, IGlobalsLike } from "./interfaces/Interfaces.sol";
import { IMapleTokenProxy, INonTransparentProxy }   from "./interfaces/IMapleTokenProxy.sol";

// MDL: The name of this contract does not match its functionality. There are no "token" aspects of this contract.
contract MapleTokenProxy is IMapleTokenProxy, NonTransparentProxy {

    bytes32 internal constant GLOBALS_SLOT = bytes32(uint256(keccak256("eip1967.proxy.globals")) - 1);

    // MDL: governor is passed to ntp to be written to admin slot, yet throughout code, governor is still fetched from globals.
    constructor(
        address globals_,
        address implementation_,
        address initializer_,
        address tokenMigrator_
    )
        NonTransparentProxy(IGlobalsLike(globals_).governor(), implementation_)
    {
        _setAddress(GLOBALS_SLOT, globals_);

        ( bool success_, ) = initializer_.delegatecall(abi.encodeWithSelector(
            IMapleTokenInitializerLike(initializer_).initialize.selector,
            tokenMigrator_,
            IGlobalsLike(globals_).mapleTreasury()
        ));

        require(success_, "MTP:INIT_FAILED");
    }

    /**************************************************************************************************************************************/
    /*** Overridden Functions                                                                                                           ***/
    /**************************************************************************************************************************************/

    function setImplementation(address newImplementation_) override(IMapleTokenProxy, NonTransparentProxy) external {
        IGlobalsLike globals_         = IGlobalsLike(_getAddress(GLOBALS_SLOT));
        bool         isScheduledCall_ = globals_.isValidScheduledCall(msg.sender, address(this), "MTP:SET_IMPLEMENTATION", msg.data);

        require(msg.sender == _admin(), "MTP:SI:NOT_ADMIN");
        require(isScheduledCall_,       "MTP:SI:NOT_SCHEDULED");

        globals_.unscheduleCall(msg.sender, "MTP:SET_IMPLEMENTATION", msg.data);

        // MDL: Can instead call `super.setImplementation(newImplementation_)` and remove the admin check above and the `_setAddress` below.

        _setAddress(IMPLEMENTATION_SLOT, newImplementation_);

        emit ImplementationSet(newImplementation_);
    }

}
