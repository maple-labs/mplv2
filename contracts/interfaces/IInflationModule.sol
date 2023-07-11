// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

// TODO: Add relevant events.
// TODO: Add a view function that returns the current schedule as an array of windows.
interface IInflationModule {

    /**************************************************************************************************************************************/
    /*** Events                                                                                                                         ***/
    /**************************************************************************************************************************************/

    /**
     * @dev    Emitted when tokens are claimed.
     * @param  amountClaimed       The amount of tokens that were claimed.
     * @param  lastClaimedWindowId The identifier of the window during which the tokens were claimed.
     */
    event Claimed(uint256 amountClaimed, uint16 lastClaimedWindowId);

    /**
     * @dev    Emitted when new windows are scheduled.
     * @param firstWindowId The identifier of the first new window that was scheduled.
     * @param lastWindowId  The identifier of the last new window that was scheduled.
     * @param windowStarts  The timestamps that mark when each windows starts.
     * @param issuanceRates The issuance rates that will be applied to each window.
     */
    event WindowsScheduled(uint16 firstWindowId, uint16 lastWindowId, uint32[] windowStarts, uint208[] issuanceRates);

    /**
     *  @dev    Claims tokens from the time of the last claim up until the current time.
     *  @return claimedAmount The amount of tokens that were claimed.
     */
    function claim() external returns (uint256 claimedAmount);

    /**
     *  @dev    Calculates how many tokens would be claimable from the time of the last claim up to the specified point in time.
     *  @return claimableAmount The amount of tokens that are claimable from the time of the last claim up to the specified time.
     */
    function claimable(uint32 to) external view returns (uint256 claimableAmount);

    /**
     *  @dev    Returns the timestamp of the last time tokens were claimed.
     *  @return lastClaimedTimestamp Timestamp of the last time tokens were claimed.
     */
    function lastClaimedTimestamp() external view returns (uint32 lastClaimedTimestamp);

    /**
     *  @dev    Returns the identifier of the window during which tokens were last claimed.
     *  @return lastClaimedWindowId Identifier of the window during which tokens were last claimed.
     */
    function lastClaimedWindowId() external view returns (uint16 lastClaimedWindowId);

    /**
     *  @dev    Returns the identifier that was assigned to the last scheduled window.
     *  @return lastScheduledWindowId Identifier that was assigned to the last scheduled window.
     */
    function lastScheduledWindowId() external view returns (uint16 lastScheduledWindowId);

    /**
     *  @dev    Returns the maximum issuance rate allowed for any window.
     *  @return maximumIssuanceRate Maximum issuance rate allowed for any window.
     */
    function maximumIssuanceRate() external view returns (uint208 maximumIssuanceRate);

    /**
     *  @dev   Schedules new windows that define when tokens will be issued.
     *  @param windowStarts  An array of window start times.
     *  @param issuanceRates An array of corresponding issuance rates.
     */
    function schedule(uint32[] memory windowStarts, uint208[] memory issuanceRates) external;

    /**
     *  @dev    Returns the address of the Maple treasury.
     *  @return token The address of the underlying token being managed.
     */
    function token() external view returns (address token);

    /**
     *  @dev    Returns thew window parameters given a window identifier.
     *  @param  windowId     The window identifier.
     *  @return nextWindowId The identifier of the window that takes effect after the provided one (zero if there is none).
     *  @return windowStart  The timestamp that marks when the window starts. It lasts until the start of the next window (or forever).
     *  @return issuanceRate The rate (per second) at which tokens will be issued (zero indicates no issuance).
     */
    function windows(uint16 windowId) external view returns (uint16 nextWindowId, uint32 windowStart, uint208 issuanceRate);

}
