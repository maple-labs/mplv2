// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

import { IEmergencyModule } from "../../contracts/interfaces/IEmergencyModule.sol";
import { IInflationModule } from "../../contracts/interfaces/IInflationModule.sol";
import { IMapleToken }      from "../../contracts/interfaces/IMapleToken.sol";

import { TestBase } from "../utils/TestBase.sol";

contract Handler is TestBase {

    IMapleToken      mapleToken;
    IEmergencyModule emergencyModule;
    IInflationModule inflationModule;

    constructor(IMapleToken mapleToken_, IEmergencyModule emergencyModule_, IInflationModule inflationModule_) {
        mapleToken      = mapleToken_;
        emergencyModule = emergencyModule_;
        inflationModule = inflationModule_;
    }

    function addModule(uint256 seed) external returns (bool skip) {
        // TODO
    }

    function approve(uint256 seed) external returns (bool skip) {
        // TODO
    }

    function claim(uint256 seed) external returns (bool skip) {
        address caller = makeAddr(vm.toString(seed));

        if (inflationModule.claimable(uint32(block.timestamp)) == 0) return true;

        vm.prank(caller);
        inflationModule.claim();
    }

    function decreaseAllowance(uint256 seed) external returns (bool skip) {
        // TODO
    }

    function emergencyBurn(uint256 seed) external returns (bool skip) {
        // TODO
    }

    function emergencyMint(uint256 seed) external returns (bool skip) {
        // TODO
    }

    function increaseAllowance(uint256 seed) external returns (bool skip) {
        // TODO
    }

    function permit(uint256 seed) external returns (bool skip) {
        // TODO
    }

    function removeModule(uint256 seed) external returns (bool skip) {
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
    }

}
