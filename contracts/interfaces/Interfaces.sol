// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

interface IERC20Like {

    function mint(address to, uint256 value) external;

    function burn(address from, uint256 value) external;

}

interface IGlobalsLike {

    function governor() external view returns (address governor);

    function mapleTreasury() external view returns (address mapleTreasury);

}
