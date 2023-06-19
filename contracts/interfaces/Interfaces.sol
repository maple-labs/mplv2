// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

interface IGlobalsLike {

    function governor() external view returns (address governor);

    function isValidScheduledCall(
        address caller,
        address target,
        bytes32 functionId,
        bytes calldata callData
    ) external view returns (bool isValidScheduledCall);

    function mapleTreasury() external view returns (address mapleTreasury);

    function unscheduleCall(address caller, address target, bytes32 functionId, bytes calldata callData) external;

}
