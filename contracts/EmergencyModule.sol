// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

import { IERC20Like, IGlobalsLike } from "./interfaces/Interfaces.sol";

contract EmergencyModule {

    address public immutable globals;
    address public immutable token;

    constructor(address _token, address _globals) {
        token   = _token;
        globals = _globals;
    }

    modifier onlyGovernor {
        require(msg.sender == IGlobalsLike(globals).governor(), "EM:NOT_GOVERNOR");
        _;
    }

    function mint(uint256 amount) external onlyGovernor {
        IERC20Like(token).mint(treasury(), amount);
    }

    function burn(address from, uint256 amount) external onlyGovernor {
        IERC20Like(token).burn(from, amount);
    }

    function treasury() internal view returns (address) {
        return IGlobalsLike(globals).mapleTreasury();
    }
    
}
