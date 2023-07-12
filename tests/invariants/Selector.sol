// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

import { Actions } from "./Actions.sol";

contract Selector is Actions {

    uint256 totalWeight;

    constructor(/*address[] memory contracts, bytes32[] memory functions, uint256[] memory weights*/) {
        // require(weight > 0, "S:ZERO_WEIGHT");

        // targets.push(target);

        // weights[target] = weight;
        // totalWeight    += weight;
    }

    // // TODO: Confirm the selection mechanism works correctly.
    // function select(uint256 seed) external view returns (address target) {
    //     uint256 distance;
    //     uint256 value = uint256(keccak256(abi.encode(seed))) % totalWeight;

    //     for (uint256 i; i < targets.length; ++i) {
    //         distance += weights[targets[i]];
    //         if (value < distance) return target;
    //     }
    // }

}
