// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

interface IGlobalsLike {

    function governor() external view returns (address governor);

    function mapleTreasury() external view returns (address mapleTreasury);

}
