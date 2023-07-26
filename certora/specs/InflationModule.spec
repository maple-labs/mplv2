using InflationModule as InflationModule;

/******************************************************************************************************************************************/
/*** Methods                                                                                                                            ***/
/******************************************************************************************************************************************/

methods {
    // InflationModule Methods
    function InflationModule.token() external returns (address) envfree;
    function InflationModule.lastClaimedTimestamp() external returns (uint32) envfree;
    function InflationModule.lastClaimedWindowId() external returns (uint16) envfree;
    function InflationModule.lastScheduledWindowId() external returns (uint16) envfree;
    function InflationModule.windows(uint16 windowId) external returns (uint16, uint32, uint208) envfree;

    // InflationModule Methods added via patch
    function InflationModule.getNextWindowId(uint16 windowId) external returns (uint256) envfree;
    function InflationModule.getWindowStart(uint16 windowId) external returns (uint256) envfree;
    function InflationModule.getIssuanceRate(uint16 windowId) external returns (uint256) envfree;

    // External Calls Summerized
    function _.globals() external => DISPATCHER(true);
    function _.governor() external => DISPATCHER(true);
    function _.mapleTreasury() external => DISPATCHER(true);
    function _.isInstanceOf(bytes32, address) external => DISPATCHER(true);
    function _.isValidScheduledCall(address, address, bytes32, bytes) external => DISPATCHER(true);
    function _.unscheduleCall(address, bytes32, bytes) external => DISPATCHER(true);
    function _.mint(address, uint256) external => DISPATCHER(true);
}

/******************************************************************************************************************************************/
/*** Definitions                                                                                                                        ***/
/******************************************************************************************************************************************/

definition isNonZeroWindowStart(uint16 windowId) returns bool =
    InflationModule.getWindowStart(windowId) != 0;

definition isNonZeroIssuanceRate(uint16 windowId) returns bool =
    InflationModule.getIssuanceRate(windowId) != 0;

definition isNonZeroNextWindowId(uint16 windowId) returns bool =
    InflationModule.getNextWindowId(windowId) != 0;

definition isWindowsEmpty(uint16 windowId) returns bool =
    !isNonZeroWindowStart(windowId) && !isNonZeroIssuanceRate(windowId) && !isNonZeroNextWindowId(windowId);

/******************************************************************************************************************************************/
/*** Invariants                                                                                                                         ***/
/******************************************************************************************************************************************/

invariant zeroWindowsScheduled(uint16 windowId)
    isWindowsEmpty(windowId)
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

invariant zeroWindowState()
    InflationModule.getWindowStart(0) == 0 && InflationModule.getIssuanceRate(0) == 0;

invariant validTailForWindowsLL()
    InflationModule.getNextWindowId(InflationModule.lastScheduledWindowId()) == 0;

/******************************************************************************************************************************************/
/*** CVL Helper Functions                                                                                                               ***/
/******************************************************************************************************************************************/

function safeAssumptions(uint16 windowId) {
    requireInvariant validTailForWindowsLL();
    requireInvariant zeroLastScheduledWindowId();
    requireInvariant zeroLastClaimedWindowId();
    requireInvariant zeroLastClaimedTimestamp();
    requireInvariant zeroWindowState();
    requireInvariant zeroWindowsScheduled(windowId);
}

function setupSchedule(env e) {
    calldataarg args;
    schedule(e, args);
}

/******************************************************************************************************************************************/
/*** Rules                                                                                                                              ***/
/******************************************************************************************************************************************/

rule LastClaimedTimestampGtePriorLastClaimedTimestamp() {
    env eClaim; uint16 windowId;

    safeAssumptions(windowId);

    mathint lastClaimedTimestampBefore = InflationModule.lastClaimedTimestamp();

    claim(eClaim);

    mathint lastClaimedTimestampAfter = InflationModule.lastClaimedTimestamp();

    assert lastClaimedTimestampAfter >= lastClaimedTimestampBefore;
}

rule LastClaimedWindowIdGtePriorLastClaimedWindowId() {
    env eClaim; uint16 windowId;

    safeAssumptions(windowId);

    mathint lastClaimedWindowIdBefore = InflationModule.lastClaimedWindowId();

    claim(eClaim);

    mathint lastClaimedWindowIdAfter = InflationModule.lastClaimedWindowId();

    assert lastClaimedWindowIdAfter >= lastClaimedWindowIdBefore;
}

rule lastScheduledWindowIdOnlyIncreases() {
    env eSchedule; uint16 windowId;

    safeAssumptions(windowId);

    mathint lastScheduledWindowIdBefore = InflationModule.lastScheduledWindowId();

    setupSchedule(eSchedule);

    mathint lastScheduledWindowIdAfter = InflationModule.lastScheduledWindowId();

    assert lastScheduledWindowIdAfter > lastScheduledWindowIdBefore;
}

rule claimableAmountDoesNotChangeForABlock() {
    env eSchedule; env e; method f; calldataarg args; uint16 windowId;

    safeAssumptions(windowId);

    uint32 eblockTimestamp         = require_uint32(e.block.timestamp);
    uint32 eScheduleblockTimestamp = require_uint32(eSchedule.block.timestamp);

    require eScheduleblockTimestamp < eblockTimestamp;

    setupSchedule(eSchedule);

    mathint claimableBefore = InflationModule.claimable(e, eblockTimestamp);

    f(e, args);

    mathint claimableAfter = InflationModule.claimable(e, eblockTimestamp);

    assert claimableBefore == claimableAfter => f.selector != sig:claim().selector;
}

rule nextWindowIdOnlyIncreases() {
    env e; method f; calldataarg args; uint16 windowId; uint16 windowId2;

    require windowId > windowId2;

    safeAssumptions(windowId);

    f(e, args);

    mathint nextWindowId  = InflationModule.getNextWindowId(windowId);
    mathint nextWindowId2 = InflationModule.getNextWindowId(windowId2);

    assert isNonZeroNextWindowId(windowId) && isNonZeroNextWindowId(windowId2) => nextWindowId > nextWindowId2;
}

rule nextWindowStartOnlyIncreases() {
    env e; method f; calldataarg args; uint16 windowId; uint16 windowId2;

    require windowId > windowId2;

    safeAssumptions(windowId);

    f(e, args);

    mathint nextWindowStart  = InflationModule.getWindowStart(windowId);
    mathint nextWindowStart2 = InflationModule.getWindowStart(windowId2);

    assert isNonZeroWindowStart(windowId) && isNonZeroWindowStart(windowId2) => nextWindowStart > nextWindowStart2;
}

rule lastClaimedTimestampLteBlockTimestamp() {
    env e; method f; calldataarg args; uint16 windowId;

    safeAssumptions(windowId);

    uint32 eblockTimestamp = require_uint32(e.block.timestamp);

    f(e, args);

    assert InflationModule.lastClaimedTimestamp() <= eblockTimestamp;
}

rule validLastClaimedTimestamp() {
    env e; env eSchedule; method f; calldataarg args; uint16 windowId;

    safeAssumptions(windowId);

    uint32 eblockTimestamp         = require_uint32(e.block.timestamp);
    uint32 eScheduleblockTimestamp = require_uint32(eSchedule.block.timestamp);

    require eScheduleblockTimestamp < eblockTimestamp;
    require eScheduleblockTimestamp > 0;  // Safe to assume as block.timestamp is always > 0

    setupSchedule(eSchedule);

    f(e, args);

    uint32 lastClaimedTimestamp = InflationModule.lastClaimedTimestamp();
    uint16 nextWindowId         = require_uint16(InflationModule.getNextWindowId(InflationModule.lastClaimedWindowId()));

    assert (lastClaimedTimestamp >= require_uint32(InflationModule.getWindowStart(InflationModule.lastClaimedWindowId()))) &&
        (nextWindowId != 0 => lastClaimedTimestamp < require_uint32(InflationModule.getWindowStart(nextWindowId)));
}