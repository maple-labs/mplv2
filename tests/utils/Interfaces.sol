// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

interface IGlobalsLike {

    function scheduledCalls(
        address caller_,
        address contract_,
        bytes32 functionId_
    ) external view returns (uint256 timestamp, bytes32 dataHash);

    function timelockParametersOf(address contract_, bytes32 functionId_) external view returns (uint128 delay, uint128 duration);

    function setTimelockWindow(address contract_, bytes32 functionId_, uint128 delay_, uint128 duration_) external;

    function isValidScheduledCall(
        address          caller_,
        address          contract_,
        bytes32          functionId_,
        bytes   calldata callData_
    ) external view returns (bool isValid_);


    function scheduleCall(address contract_, bytes32 functionId_, bytes calldata callData_) external;

    function unscheduleCall(address caller_, bytes32 functionId_, bytes calldata callData_) external;

    function unscheduleCall(address caller_, address contract_, bytes32 functionId_, bytes calldata callData_) external; 
}
