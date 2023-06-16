// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

import { ERC20Proxied }          from "../modules/erc20/contracts/ERC20Proxied.sol";
import { NonTransparentProxied } from "../modules/ntp/contracts/NonTransparentProxied.sol";

import { IGlobalsLike }        from "./interfaces/Interfaces.sol";
import { IMapleToken, IERC20 } from "./interfaces/IMapleToken.sol";

contract MapleToken is IMapleToken, ERC20Proxied, NonTransparentProxied {

    bytes32 internal constant GLOBALS_SLOT = bytes32(uint256(keccak256("eip1967.proxy.globals")) - 1);

    mapping(address => bool) public isBurner;
    mapping(address => bool) public isMinter;

    modifier onlyGovernor {
        require(msg.sender == IGlobalsLike(globals()).governor(), "MT:NOT_GOVERNOR");
        _;
    }

    /**************************************************************************************************************************************/
    /*** External Functions                                                                                                             ***/
    /**************************************************************************************************************************************/
   
   // Note: technically, a module can be removed with this function, but that's alright, since it's more restrictive than removeModule()
    function addModule(address module, bool burner, bool minter) external onlyGovernor {
        require(burner || minter, "MT:AM:INVALID_MODULE");
        // TODO: add scheduling
        
        isBurner[module] = burner;
        isMinter[module] = minter;
    }

    function removeModule(address module) external onlyGovernor {
        delete isBurner[module];
        delete isMinter[module];
    }

    function burn(address from_, uint256 amount_) external {
        require(isBurner[msg.sender], "MT:B:NOT_BURNER");
        _burn(from_, amount_);
    }

    function mint(uint256 amount_) external  {
        require(isMinter[msg.sender], "MT:M:NOT_MINTER");
        _mint(IGlobalsLike(globals()).mapleTreasury(), amount_);
    }

    /**************************************************************************************************************************************/
    /*** Pure Functions                                                                                                                 ***/
    /**************************************************************************************************************************************/

    function decimals() public pure override(ERC20Proxied, IERC20) returns (uint8 decimals_) {
        decimals_ = 18;
    }

    function name() public pure override(ERC20Proxied, IERC20) returns (string memory name_) {
        name_ = "MPL";
    }

    function symbol() public pure override(ERC20Proxied, IERC20) returns (string memory symbol_) {
        symbol_ = "MPL";
    }

    /**************************************************************************************************************************************/
    /*** View Functions                                                                                                                 ***/
    /**************************************************************************************************************************************/

    function globals() public view override returns (address globals_) {
        globals_ = _getAddress(GLOBALS_SLOT);
    }

}
