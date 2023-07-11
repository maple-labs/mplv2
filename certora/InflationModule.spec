using InflationModule as InflationModule;

methods {
    function InflationModule._globals() external returns (address) envfree;
    function InflationModule.token() external returns (address) envfree;
    function InflationModule.lastClaimedTimestamp() external returns (uint32) envfree;
    function InflationModule.lastClaimedWindowId() external returns (uint16) envfree;
    function InflationModule.lastScheduledWindowId() external returns (uint16) envfree;
    function InflationModule.maximumIssuanceRate() external returns (uint208) envfree;
    function InflationModule.windows(uint16 windowId) external returns (uint16, uint32, uint208) envfree;
    function _.globals() external => DISPATCHER(true);
    function _.governor() external => DISPATCHER(true);
    function _.mapleTreasury() external => DISPATCHER(true);
    function _.isValidScheduledCall(address, address, bytes32, bytes) external => DISPATCHER(true);
    function _.unscheduleCall(address, bytes32, bytes) external => DISPATCHER(true);
    function _.mint(address, uint256) external => DISPATCHER(true);
}

rule LastClaimedTimestampRule() {
    env eClaim;

    mathint lastClaimedTimestampBefore = InflationModule.lastClaimedTimestamp();

    claim(eClaim);
    
    mathint lastClaimedTimestampAfter = InflationModule.lastClaimedTimestamp();

    assert lastClaimedTimestampAfter >= lastClaimedTimestampBefore;
}

rule LastClaimedWindowIdRule() {
    env eSchedule; env eClaim; calldataarg args;

    require InflationModule.lastClaimedWindowId() == 0;

    mathint lastClaimedWindowIdBefore = InflationModule.lastClaimedWindowId();

    schedule(eSchedule, args);
    claim(eClaim);

    mathint lastClaimedWindowIdAfter = InflationModule.lastClaimedWindowId();

    assert lastClaimedWindowIdAfter >= lastClaimedWindowIdBefore;
}

rule lastScheduledWindowIdRule() {
    env eSchedule; calldataarg args;

    mathint lastScheduledWindowIdBefore = InflationModule.lastScheduledWindowId();

    schedule(eSchedule, args);

    mathint lastScheduledWindowIdAfter = InflationModule.lastScheduledWindowId();

    assert lastScheduledWindowIdAfter >= lastScheduledWindowIdBefore;
}

/// Used to check that a method does not have a reachablity vacuity.
/// This rule is expected to always fail.
// rule MethodsVacuityCheck(method f) {
// 	env e; calldataarg args;
// 	f(e, args);
// 	assert false;
// }
