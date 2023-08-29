// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

import { MapleAddressRegistry } from "../../modules/address-registry/contracts/MapleAddressRegistry.sol";

contract ProcedureAddressRegistry is MapleAddressRegistry {

    address migrator                = address(0);
    address mplv2Implementation     = address(0);
    address mplv2Initializer        = address(0);
    address mplv2Proxy              = address(0); 
    address recapitalizationClaimer = address(0x6b1A78C1943b03086F7Ee53360f9b0672bD60818);
    address recapitalizationModule  = address(0);

}
