// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

interface IERC20Like {

    function mint(address _to, uint256 _value) external;

    function burn(address _from, uint256 _value) external;

}

interface IGlobalsLike {

    function governor() external view returns (address governor);

    function mapleTreasury() external view returns (address mapleTreasury);

}
