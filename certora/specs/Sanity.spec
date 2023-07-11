/// Used to check that a method does not have a reachablity vacuity.
/// This rule is expected to always fail.
rule VacuityCheck(method f) {
	env e; calldataarg args;
	f(e, args);
	assert false;
}
