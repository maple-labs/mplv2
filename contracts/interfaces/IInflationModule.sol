// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

interface IInflationModule {

    /**
     *  @dev    Returns the address of the Maple Globals contract.
     *  @return globals The address of the Maple Globals contract.
     */
    function globals() external view returns (address globals);

    /**
     *  @dev    Returns the address of the Maple treasury.
     *  @return token The address of the underlying token being managed.
     */
    function token() external view returns (address token);

    /**
     *  @dev    Returns the total number of new windows created so far.
     *  @return windowCounter The total number of new windows created so far.
     */
    function windowCounter() external view returns (uint16 windowCounter);

    /**
     *  @dev    Returns the timestamp of the last time tokens were claimed.
     *  @return lastClaimed The timestamp of the last time tokens were claimed.
     */
    function lastClaimed() external view returns (uint32 lastClaimed);

    /**
     *  @dev    Returns the maximum issuance rate allowed for any window (to prevent overflows).
     *  @return maximumIssuanceRate The maximum issuance rate allowed for any window.
     */
    function maximumIssuanceRate() external view returns (uint208 maximumIssuanceRate);

    /**
     *  @dev    Returns thew window parameters given a window identifier.
     *  @param  windowId     The window identifier.
     *  @return nextWindowId The identifier of the window that takes effect after the provided one (zero if there is none).
     *  @return windowStart  The timestamp that marks when the window starts. It lasts until the start of the next window (or forever).
     *  @return issuanceRate The rate (per second) at which tokens will be issued (zero indicates no issuance).
     */
    function windows(uint16 windowId) external view returns (uint16 nextWindowId, uint32 windowStart, uint208 issuanceRate);

    /**
     *  @dev    Claims tokens from the time of the last claim up until the current time.
     *  @return claimedAmount The amount of token that was minted in this claim.
     */
    function claim() external returns (uint256 claimedAmount);

    /**
     *  @dev    Calculates how many tokens that would be claimed if `claim` is called right now.
     *  @return claimableAmount The amount of token that are claimable from the time of the last claim up until now.
     */
    function claimable() external view returns (uint256 claimableAmount);

    /**
     *  @dev    Calculates how many tokens can be claimed from a specified start time to end time.
     *  @param  from            The start of a time span.
     *  @param  to              The end of a time span.
     *  @return claimableAmount The amount of token that are claimable during this period.
     */
    function claimable(uint32 from, uint32 to) external view returns (uint256 claimableAmount);

    /**
     *  @dev   Schedules new windows that define when tokens will be issued.
     *  @param windowStarts  An array of window start times.
     *  @param issuanceRates An array of corresponding issuance rates.
     */
    function schedule(uint32[] memory windowStarts, uint208[] memory issuanceRates) external;

    /**
     *  @dev   Sets a new limit to the maximum issuance rate allowed for any window.
     *  @param maximumIssuanceRate The new maximum issuance rate allowed for any window.
     */
    function setMaximumIssuanceRate(uint192 maximumIssuanceRate) external;

}
