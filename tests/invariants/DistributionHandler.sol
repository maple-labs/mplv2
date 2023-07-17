// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

contract DistributionHandler {

    address target;

    uint256 totalWeight;

    bytes4[] selectors;

    uint256[] weights;

    constructor(address target_, bytes4[] memory selectors_, uint256[] memory weights_) {
        target = target_;

        for (uint i; i < selectors_.length; ++i) {
            require(weights_[i] > 0, "R:C:ZERO_WEIGHT");

            selectors.push(selectors_[i]);
            weights.push(weights_[i]);

            totalWeight += weights_[i];
        }
    }

    function call(uint256 weightSeed, uint256 dataSeed) external {
        while (true) {
            bytes4 selector = findSelector(weightSeed % totalWeight);

            ( bool success, bytes memory output ) = target.call(abi.encodeWithSelector(selector, dataSeed));

            assert(success);

            bool skip = abi.decode(output, (bool));

            if (!skip) break;

            weightSeed = uint256(keccak256(abi.encode(weightSeed)));
        }
    }

    function findSelector(uint256 weight) internal view returns (bytes4 selector) {
        uint256 runningWeight;

        for (uint256 i; i < selectors.length; ++i) {
            runningWeight += weights[i];
            if (runningWeight > weight) return selectors[i];
        }
    }

}
