// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.13;

import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "../errors/Errors.sol";
import "../hub/IHub.sol";
import "../proxy/MasterCopyNonUpgradable.sol";
import "./IStandardVault.sol";

contract StandardVault is MasterCopyNonUpgradable, ERC1155Holder, IStandardVault, ICirclesErrors {
    // State variables

    /**
     * @notice Address of the standard treasury
     */
    address public standardTreasury;

    /**
     * @notice Address of the hub contract
     */
    IHubV2 public hub;

    // Modifiers

    /**
     * @notice Ensure the caller is the standard treasury
     */
    modifier onlyTreasury() {
        if (msg.sender != standardTreasury) {
            // Vault: caller is not the treasury
            revert CirclesInvalidFunctionCaller(msg.sender, standardTreasury, 0);
        }
        _;
    }

    // Constructor

    /**
     * @notice Constructor to create a standard vault master copy.
     */
    constructor() {
        // set the standard treasury to a blocked address for the master copy deployment
        standardTreasury = address(1);
        hub = IHubV2(address(1));
    }

    // External functions

    /**
     * @notice Setup the vault
     * @param _hub Address of the hub contract
     */
    function setup(IHubV2 _hub) external {
        if (address(hub) != address(0)) {
            // Vault: already initialized
            revert CirclesProxyAlreadyInitialized();
        }
        standardTreasury = msg.sender;
        hub = _hub;
    }

    /**
     * Return the collateral to the receiver can only be called by the treasury
     * @param _receiver Receivere address of the collateral
     * @param _ids Circles identifiers of the collateral
     * @param _values Values of the collateral to be returned
     * @param _data Optional data bytes passed to the receiver
     */
    function returnCollateral(
        address _receiver,
        uint256[] calldata _ids,
        uint256[] calldata _values,
        bytes calldata _data
    ) external onlyTreasury {
        if (_receiver == address(0)) {
            // Vault: receiver cannot be 0 address
            revert CirclesAddressCannotBeZero(0);
        }

        // return the collateral to the receiver
        hub.safeBatchTransferFrom(address(this), _receiver, _ids, _values, _data);
    }

    /**
     * @notice Burn collateral from the vault can only ve called by the treasury
     * @param _ids Circles identifiers of the collateral
     * @param _values Values of the collateral to be burnt
     * @param _data Optional data bytes passed to the hub and policy for burning
     */
    function burnCollateral(uint256[] calldata _ids, uint256[] calldata _values, bytes calldata _data)
        external
        onlyTreasury
    {
        if (_ids.length != _values.length) {
            // Vault: ids and values length mismatch
            revert CirclesArraysLengthMismatch(_ids.length, _values.length, 0);
        }

        // burn the collateral from the vault
        for (uint256 i = 0; i < _ids.length; i++) {
            hub.burn(_ids[i], _values[i], _data);
        }
    }
}
