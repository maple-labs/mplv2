// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

import { ERC20Proxied }          from "../modules/erc20/contracts/ERC20Proxied.sol";
import { NonTransparentProxied } from "../modules/ntp/contracts/NonTransparentProxied.sol";

import { IGlobalsLike } from "./interfaces/Interfaces.sol";
import { IMapleToken }  from "./interfaces/IMapleToken.sol";

// MDL: Make sure a module is on chain, and not just an address, when scheduling. Token holders won't know what is being scheduled.
// MDL: Make sure contract exists at `addModule`.

contract MapleToken is IMapleToken, ERC20Proxied, NonTransparentProxied {

    bytes32 internal constant GLOBALS_SLOT = bytes32(uint256(keccak256("eip1967.proxy.globals")) - 1);

    // MDL: If the modules have a fixed implementation at each address (unless the modules are proxies) then a non-burner and non-minter
    //      will never become a burner or minter respectively. Further, modules are being approved based on their implementation, which is
    //      known ahead of time, so perhaps a `isModule` mapping is more efficient.
    mapping(address => bool) public isBurner;
    mapping(address => bool) public isMinter;

    modifier onlyGovernor {
        // MDL: There is the option adopt Custom Errors, but I guess this can be done later since this contract is upgradeable.
        // MDL: It's odd and possibly error-prone that governor is both from globals in the eip1967 admin slot.
        require(msg.sender == IGlobalsLike(globals()).governor(), "MT:NOT_GOVERNOR");

        _;
    }

    modifier onlyScheduled(bytes32 functionId_) {
        IGlobalsLike globals_         = IGlobalsLike(globals());
        bool         isScheduledCall_ = globals_.isValidScheduledCall(msg.sender, address(this), functionId_, msg.data);

        // MDL: Can inline the `isScheduledCall_` fetch, saving some runtime gas for stack manipulations.
        require(isScheduledCall_, "MT:NOT_SCHEDULED");

        globals_.unscheduleCall(msg.sender, functionId_, msg.data);

        _;
    }

    /**************************************************************************************************************************************/
    /*** External Functions                                                                                                             ***/
    /**************************************************************************************************************************************/

    // Note: Technically, a module can be removed with this function, but that's alright, since it's more restrictive than `removeModule()`.
    // MDL: In light of the above comment, the `ModuleAdded` is ambiguous and counterintuitive. IMHO, there ae two cleaner ways:
    //        - `addBurner`, `addMinter`, `removeBurner`, `removeMinter`
    //        - `setModule` (which does exactly what `addModule` does, but emits a better-named event, and we no longer need `removeModule`)
    //          * This also works well with if an `isModule` mapping is favoured over `isBurner` and `isMinter` mappings.
    function addModule(address module, bool burner, bool minter) external onlyGovernor onlyScheduled("MT:ADD_MODULE") {
        require(burner || minter, "MT:AM:INVALID_MODULE");

        isBurner[module] = burner;
        isMinter[module] = minter;

        emit ModuleAdded(module, burner, minter);
    }

    function removeModule(address module) external onlyGovernor onlyScheduled("MT:REMOVE_MODULE") {
        delete isBurner[module];
        delete isMinter[module];

        emit ModuleRemoved(module);
    }

    function burn(address from_, uint256 amount_) external {
        require(isBurner[msg.sender], "MT:B:NOT_BURNER");
        _burn(from_, amount_);
    }

    function mint(address to_, uint256 amount_) external  {
        require(isMinter[msg.sender], "MT:M:NOT_MINTER");
        _mint(to_, amount_);
    }

    /**************************************************************************************************************************************/
    /*** View Functions                                                                                                                 ***/
    /**************************************************************************************************************************************/

    function globals() public view returns (address globals_) {
        globals_ = _getAddress(GLOBALS_SLOT);
    }

}
