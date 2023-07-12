// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

import { IEmergencyModule } from "../../contracts/interfaces/IEmergencyModule.sol";
import { IInflationModule } from "../../contracts/interfaces/IInflationModule.sol";
import { IMapleToken }      from "../../contracts/interfaces/IMapleToken.sol";

import { IGlobalsLike } from "../utils/Interfaces.sol";

import { TestBase } from "../utils/TestBase.sol";

contract Handler is TestBase {

    IGlobalsLike mapleGlobals;
    IMapleToken  mapleToken;

    IEmergencyModule emergencyModule;
    IInflationModule inflationModule;

    constructor(IGlobalsLike mapleGlobals_, IMapleToken mapleToken_, IEmergencyModule emergencyModule_, IInflationModule inflationModule_) {
        mapleGlobals    = mapleGlobals_;
        mapleToken      = mapleToken_;
        emergencyModule = emergencyModule_;
        inflationModule = inflationModule_;
    }

    function approve(uint256 seed) external returns (bool skip) {
        // TODO
    }

    function claim(uint256 seed) external returns (bool skip) {
        address caller = makeAddr(vm.toString(seed));

        // Skip if nothing is claimable.
        if (inflationModule.claimable(uint32(block.timestamp)) == 0) return true;

        vm.prank(caller);
        inflationModule.claim();
    }

    function decreaseAllowance(uint256 seed) external returns (bool skip) {
        // TODO
    }

    function emergencyBurn(uint256 seed) external returns (bool skip) {
        address treasury = mapleGlobals.mapleTreasury();
        uint256 balance  = mapleToken.balanceOf(treasury);

        // Skip if no tokens can be burned.
        if (balance == 0) return true;

        address governor = mapleGlobals.governor();
        uint256 amount   = bound(seed, 1, balance);

        vm.prank(governor);
        emergencyModule.burn(treasury, amount);
    }

    function emergencyMint(uint256 seed) external returns (bool skip) {
        uint256 totalSupply = mapleToken.totalSupply();

        // Skip if no tokens can be minted.
        if (totalSupply == type(uint256).max) return true;

        address governor = mapleGlobals.governor();
        uint256 amount   = bound(seed, 1, type(uint256).max - totalSupply);

        vm.prank(governor);
        emergencyModule.mint(amount);
    }

    function increaseAllowance(uint256 seed) external returns (bool skip) {
        // TODO
    }

    function permit(uint256 seed) external returns (bool skip) {
        // TODO
    }

    function schedule(uint256 seed) external returns (bool skip) {
        // TODO
    }

    function transfer(uint256 seed) external returns (bool skip) {
        // TODO
    }

    function transferFrom(uint256 seed) external returns (bool skip) {
        // TODO
    }

    function warp(uint256 seed) external returns (bool skip) {
        uint256 time = bound(seed, 1 seconds, 30 days);

        vm.warp(block.timestamp + time);

        return false;
    }

}
