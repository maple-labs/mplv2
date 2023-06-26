// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

import { NonTransparentProxy } from "../modules/ntp/contracts/NonTransparentProxy.sol";

import { IMapleTokenInitializerLike, IGlobalsLike } from "./interfaces/Interfaces.sol";

contract MapleTokenProxy is NonTransparentProxy {

    bytes32 internal constant GLOBALS_SLOT = bytes32(uint256(keccak256("eip1967.proxy.globals")) - 1);

    constructor(
        address globals_,
        address implementation_,
        address initializer_,
        address migrator_
    )
        NonTransparentProxy(IGlobalsLike(globals_).governor(), implementation_)
    {
        _setAddress(GLOBALS_SLOT, globals_);

        ( bool success_, ) = initializer_.delegatecall(abi.encodeWithSelector(
            IMapleTokenInitializerLike(initializer_).initialize.selector,
            migrator_,
            IGlobalsLike(globals_).mapleTreasury()
        ));

        require(success_, "MTP:INIT_FAILED");
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
