using InflationModule as InflationModule;

methods {
    function globals() external returns (address) envfree;
    function token() external returns (address) envfree;
    function windowCounter() external returns (uint16) envfree;
    function lastClaimed() external returns (uint32) envfree;
    function maximumIssuanceRate() external returns (uint208) envfree;
    function _.governor() external => DISPATCHER(true);
    function _.isValidScheduledCall(address, address, bytes32, bytes) external => ALWAYS(true);
    function _.unscheduleCall(address, bytes32, bytes) external => DISPATCHER(true);
}

rule MaximumIssuanceRateSpec(env e, uint192 maxIR) {
    InflationModule.setMaximumIssuanceRate(e, maxIR);
    assert maxIR == assert_uint192(InflationModule.maximumIssuanceRate());
}

/// Used to check that a method does not have a reachablity vacuity.
/// This rule is expected to always fail.
// rule MethodsVacuityCheck(method f) {
// 	env e; calldataarg args;
// 	f(e, args);
// 	assert false;
// }
