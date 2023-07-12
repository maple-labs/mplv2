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

    function act(uint256 weightSeed, uint256 dataSeed) external {
        uint256 index = select(weightSeed % totalWeight);

        ( bool success, ) = target.call(abi.encodeWithSelector(selectors[index], dataSeed));

        require(success, "Action failed!");
    }

    function select(uint256 selectedWeight) internal view returns (uint256 index) {
        uint256 accumulatedWeight;

        for (; index < selectors.length; ++index) {
            accumulatedWeight += weights[index];
            if (accumulatedWeight > selectedWeight) break;
        }
    }

}
