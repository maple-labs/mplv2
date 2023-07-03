// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

import { INonTransparentProxy } from "../../modules/ntp/contracts/interfaces/INonTransparentProxy.sol";

interface IMapleTokenProxy is INonTransparentProxy {

    /**
     *  @dev   Emitted when the implementation address is set.
     *  @param implementation The address of the new implementation.
     */
    event ImplementationSet(address implementation);

    /**
     *  @dev   Sets the implementation address.
     *  @param newImplementation The address to set the implementation to.
     */
    function setImplementation(address newImplementation) external override;

}
