using InflationModule as InflationModule;

methods {
    // InflationModule Methods
    function InflationModule._globals() external returns (address) envfree;
    function InflationModule.token() external returns (address) envfree;
    function InflationModule.lastClaimedTimestamp() external returns (uint32) envfree;
    function InflationModule.lastClaimedWindowId() external returns (uint16) envfree;
    function InflationModule.lastScheduledWindowId() external returns (uint16) envfree;
    function InflationModule.maximumIssuanceRate() external returns (uint208) envfree;
    function InflationModule.windows(uint16 windowId) external returns (uint16, uint32, uint208) envfree;
    function InflationModule.getNextWindowId(uint16 windowId) external returns (uint256) envfree;
    function InflationModule.getWindowStart(uint16 windowId) external returns (uint256) envfree;
    function InflationModule.getIssuanceRate(uint16 windowId) external returns (uint256) envfree;

    // External Calls Summerized
    function _.globals() external => DISPATCHER(true);
    function _.governor() external => DISPATCHER(true);
    function _.mapleTreasury() external => DISPATCHER(true);
    function _.isValidScheduledCall(address, address, bytes32, bytes) external => DISPATCHER(true);
    function _.unscheduleCall(address, bytes32, bytes) external => DISPATCHER(true);
    function _.mint(address, uint256) external => DISPATCHER(true);
}

definition isWindowScheduled(uint16 windowId) returns bool =
    InflationModule.getWindowStart(windowId) != 0;

definition isNonZeroIssuanceRate(uint16 windowId) returns bool =
    InflationModule.getIssuanceRate(windowId) != 0;

definition isNonZeroNextWindowId(uint16 windowId) returns bool =
    InflationModule.getNextWindowId(windowId) != 0;

definition isWindowsEmpty(uint16 windowId) returns bool =
    !isWindowScheduled(windowId) && !isNonZeroIssuanceRate(windowId) && !isNonZeroNextWindowId(windowId);

invariant zeroWindowsScheduled()
    isWindowsEmpty(1)
    filtered { f -> f.selector != sig:schedule(uint32[], uint208[]).selector }

invariant zeroLastScheduledWindowId()
    InflationModule.lastScheduledWindowId() == 0
    filtered { f -> f.selector != sig:schedule(uint32[], uint208[]).selector }

invariant zeroLastClaimedWindowId()
    InflationModule.lastClaimedWindowId() == 0
    filtered { f -> f.selector != sig:claim().selector }

invariant zeroLastClaimedTimestamp()
    InflationModule.lastClaimedTimestamp() == 0
    filtered { f -> f.selector != sig:claim().selector }

function safeAssumptions() {
    requireInvariant zeroWindowsScheduled();
    requireInvariant zeroLastScheduledWindowId();
    requireInvariant zeroLastClaimedWindowId();
    requireInvariant zeroLastClaimedTimestamp();
}

rule LastClaimedTimestampRule() {
    env eClaim;

    safeAssumptions();

    mathint lastClaimedTimestampBefore = InflationModule.lastClaimedTimestamp();

    claim(eClaim);

    mathint lastClaimedTimestampAfter = InflationModule.lastClaimedTimestamp();

    assert lastClaimedTimestampAfter >= lastClaimedTimestampBefore;
}

rule LastClaimedWindowIdRule() {
    env eSchedule; env eClaim; calldataarg args;

    safeAssumptions();

    mathint lastClaimedWindowIdBefore = InflationModule.lastClaimedWindowId();

    schedule(eSchedule, args);

    claim(eClaim);

    mathint lastClaimedWindowIdAfter = InflationModule.lastClaimedWindowId();

    assert lastClaimedWindowIdAfter >= lastClaimedWindowIdBefore;
}

rule lastScheduledWindowIdRule() {
    env eSchedule; calldataarg args;

    safeAssumptions();

    mathint lastScheduledWindowIdBefore = InflationModule.lastScheduledWindowId();

    schedule(eSchedule, args);

    mathint lastScheduledWindowIdAfter = InflationModule.lastScheduledWindowId();

    assert lastScheduledWindowIdAfter >= lastScheduledWindowIdBefore;
}
