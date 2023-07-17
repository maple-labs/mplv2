// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

import { IEmergencyModule } from "../../contracts/interfaces/IEmergencyModule.sol";
import { IInflationModule } from "../../contracts/interfaces/IInflationModule.sol";
import { IMapleToken }      from "../../contracts/interfaces/IMapleToken.sol";

import { IGlobalsLike } from "../utils/Interfaces.sol";

import { TestBase } from "../utils/TestBase.sol";

contract Handler is TestBase {

    address claimer;

    uint32 public blockTimestamp;

    IGlobalsLike mapleGlobals;
    IMapleToken  mapleToken;

    IEmergencyModule emergencyModule;
    IInflationModule inflationModule;

    mapping(address => uint256) allowances;
    mapping(address => uint256) balances;

    modifier useBlockTimestamp() {
        vm.warp(blockTimestamp);

        _;
    }

    constructor(
        IGlobalsLike mapleGlobals_,
        IMapleToken mapleToken_,
        IEmergencyModule emergencyModule_,
        IInflationModule inflationModule_,
        address claimer_
    )
    {
        mapleGlobals    = mapleGlobals_;
        mapleToken      = mapleToken_;
        emergencyModule = emergencyModule_;
        inflationModule = inflationModule_;

        claimer = claimer_;

        blockTimestamp = uint32(block.timestamp);
    }

    function approve(uint256 seed) external returns (bool skip) {
        // TODO
    }

    function claim(uint256) external useBlockTimestamp returns (bool skip) {
        // Skip if nothing is claimable.
        if (inflationModule.claimable(blockTimestamp) == 0) return true;

        vm.prank(claimer);
        inflationModule.claim();
    }

    function decreaseAllowance(uint256 seed) external returns (bool skip) {
        // TODO
    }

    function emergencyBurn(uint256 seed) external useBlockTimestamp returns (bool skip) {
        address treasury = mapleGlobals.mapleTreasury();
        uint256 balance  = mapleToken.balanceOf(treasury);

        // Skip if no tokens can be burned.
        if (balance == 0) return true;

        address governor = mapleGlobals.governor();
        uint256 amount   = bound(seed, 1, balance);

        vm.prank(governor);
        emergencyModule.burn(treasury, amount);
    }

    function emergencyMint(uint256 seed) external useBlockTimestamp returns (bool skip) {
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

    function schedule(uint256 seed) external useBlockTimestamp returns (bool skip) {
        uint256 numberOfWindows = bound(seed, 1, 10);

        uint32[]  memory windowStarts  = new uint32[](numberOfWindows);
        uint208[] memory issuanceRates = new uint208[](numberOfWindows);

        uint32 minWindowStart = uint32(blockTimestamp);

        for (uint i; i < numberOfWindows; ++i) {
            uint256 windowSeed = uint256(keccak256(abi.encode(seed, i)));

            windowStarts[i]  = uint32(bound(windowSeed, minWindowStart, minWindowStart + 100 days));
            issuanceRates[i] = uint208(bound(windowSeed, 0, 1e18));

            minWindowStart = windowStarts[i] + 1 seconds;
        }

        address governor = mapleGlobals.governor();

        vm.prank(governor);
        mapleGlobals.scheduleCall(
            address(inflationModule),
            "IM:SCHEDULE",
            abi.encodeWithSelector(inflationModule.schedule.selector, windowStarts, issuanceRates)
        );

        vm.prank(governor);
        inflationModule.schedule(windowStarts, issuanceRates);

        return false;
    }

    function transfer(uint256 seed) external returns (bool skip) {
        // TODO
    }

    function transferFrom(uint256 seed) external returns (bool skip) {
        // TODO
    }

    function warp(uint256 seed) external returns (bool skip) {
        blockTimestamp += uint32(bound(seed, 1 seconds, 1000 days));

        return false;
    }

}
