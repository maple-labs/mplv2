// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

import { INonTransparentProxy } from "../../modules/ntp/contracts/interfaces/INonTransparentProxy.sol";

// MDL: The name of this contract does not match its functionality. There are no "token" aspects of this interface.
interface IMapleTokenProxy is INonTransparentProxy {

    // MDL: `event ImplementationSet` should be added to `INonTransparentProxy`.
    /**
     *  @dev   Emitted when the implementation address is set.
     *  @param implementation The address of the new implementation.
     */
    event ImplementationSet(address indexed implementation);

    /**
     *  @dev   Sets the implementation address.
     *  @param newImplementation The address to set the implementation to.
     */
    function setImplementation(address newImplementation) external;

}
