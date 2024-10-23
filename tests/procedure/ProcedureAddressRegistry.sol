// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

import { MapleAddressRegistry } from "../../modules/address-registry/contracts/MapleAddressRegistry.sol";

contract ProcedureAddressRegistry is MapleAddressRegistry {

    address migrator                = address(0x9c9499edD0cd2dCBc3C9Dd5070bAf54777AD8F2C);
    address mplv2Implementation     = address(0x6eD767EBCfF51533E5181f7bf818F2b9bD767aec);
    address mplv2Initializer        = address(0xfE4a4fd3bd2E0Eb400355aeF5Aa1752bC54B30FC);
    address mplv2Proxy              = address(0x643C4E15d7d62Ad0aBeC4a9BD4b001aA3Ef52d66);
    address recapitalizationClaimer = address(0x6b1A78C1943b03086F7Ee53360f9b0672bD60818);
    address recapitalizationModule  = address(0x5dfe0460f66fa06bFCbB3211e723556be6B3f69D);
    address stSyrup                 = address(0xc7E8b36E0766D9B04c93De68A9D47dD11f260B45);

}
