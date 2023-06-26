// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

interface IERC20Like {

    function mint(address to, uint256 value) external;

    function burn(address from, uint256 value) external;

}

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

interface IMapleTokenInitializerLike {

    function initialize(address migrator, address treasury) external;

}
