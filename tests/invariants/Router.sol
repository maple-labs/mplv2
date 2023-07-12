// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

contract Router {

    address target;

    uint256 totalWeight;

    bytes4[] selectors;

    uint256[] weights;

    constructor(address target_, bytes4[] memory selectors_, uint256[] memory weights_) {
        target = target_;

        for (uint i; i < selectors_.length; ++i) {
            require(weights_[i] > 0, "S:C:ZERO_WEIGHT");

            selectors.push(selectors_[i]);
            weights.push(weights_[i]);

            totalWeight += weights_[i];
        }
    }

    function call(uint256 weightSeed, uint256 dataSeed) external {
        while (true) {
            uint256 index = select(weightSeed % totalWeight);

            ( bool success, bytes memory output ) = target.call(abi.encodeWithSelector(selectors[index], dataSeed));

            assert(success);

            bool skip = abi.decode(output, (bool));

            if (!skip) break;

            weightSeed = uint256(keccak256(abi.encode(weightSeed)));
            dataSeed   = uint256(keccak256(abi.encode(dataSeed)));
        }
    }

    function select(uint256 selectedWeight) internal view returns (uint256 index) {
        uint256 accumulatedWeight;

        for (; index < selectors.length; ++index) {
            accumulatedWeight += weights[index];
            if (accumulatedWeight > selectedWeight) break;
        }
    }

}
