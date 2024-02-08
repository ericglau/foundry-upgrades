// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Options, DefenderOptions} from "./Options.sol";
import {Upgrades} from "./Upgrades.sol";
import {DefenderDeploy} from "./internal/DefenderDeploy.sol";

/**
 * @dev Library for interacting with OpenZeppelin Defender from Forge scripts or tests.
 */
library Defender {
    /**
     * @dev Deploys a contract to the current network using OpenZeppelin Defender.
     *
     * WARNING: Do not use this function directly if you are deploying an upgradeable contract. This function does not validate whether the contract is upgrade safe.
     *
     * @param contractName Name of the contract to deploy, e.g. "MyContract.sol" or "MyContract.sol:MyContract" or artifact path relative to the project root directory
     * @return Address of the deployed contract
     */
    function deployContract(string memory contractName) internal returns (address) {
        return deployContract(contractName, "");
    }

    /**
     * @dev Deploys a contract to the current network using OpenZeppelin Defender.
     *
     * WARNING: Do not use this function directly if you are deploying an upgradeable contract. This function does not validate whether the contract is upgrade safe.
     *
     * @param contractName Name of the contract to deploy, e.g. "MyContract.sol" or "MyContract.sol:MyContract" or artifact path relative to the project root directory
     * @param opts Defender deployment options. Note that the `useDefenderDeploy` option is always treated as `true` when called from this function.
     * @return Address of the deployed contract
     */
    function deployContract(string memory contractName, DefenderOptions memory opts) internal returns (address) {
        return deployContract(contractName, "", opts);
    }

    /**
     * @dev Deploys a contract with constructor arguments to the current network using OpenZeppelin Defender.
     *
     * WARNING: Do not use this function directly if you are deploying an upgradeable contract. This function does not validate whether the contract is upgrade safe.
     *
     * @param contractName Name of the contract to deploy, e.g. "MyContract.sol" or "MyContract.sol:MyContract" or artifact path relative to the project root directory
     * @param constructorData Encoded constructor arguments
     * @return Address of the deployed contract
     */
    function deployContract(string memory contractName, bytes memory constructorData) internal returns (address) {
        DefenderOptions memory opts;
        return deployContract(contractName, constructorData, opts);
    }

    /**
     * @dev Deploys a contract with constructor arguments to the current network using OpenZeppelin Defender.
     *
     * WARNING: Do not use this function directly if you are deploying an upgradeable contract. This function does not validate whether the contract is upgrade safe.
     *
     * @param contractName Name of the contract to deploy, e.g. "MyContract.sol" or "MyContract.sol:MyContract" or artifact path relative to the project root directory
     * @param constructorData Encoded constructor arguments
     * @param opts Defender deployment options. Note that the `useDefenderDeploy` option is always treated as `true` when called from this function.
     * @return Address of the deployed contract
     */
    function deployContract(
        string memory contractName,
        bytes memory constructorData,
        DefenderOptions memory opts
    ) internal returns (address) {
        return DefenderDeploy.deploy(contractName, constructorData, opts);
    }

    /**
     * @dev Proposes an upgrade to an upgradeable proxy using OpenZeppelin Defender.
     *
     * This function validates a new implementation contract in comparison with a reference contract, deploys the new implementation contract using Defender,
     * and proposes an upgrade to the new implementation contract using an upgrade approval process on Defender.
     *
     * Supported for UUPS or Transparent proxies. Not currently supported for beacon proxies or beacons.
     * For beacons, use `Upgrades.prepareUpgrade` along with a transaction proposal on Defender to upgrade the beacon to the deployed implementation.
     *
     * Requires that either the `referenceContract` option is set, or the contract has a `@custom:oz-upgrades-from <reference>` annotation.
     *
     * WARNING: Ensure that the reference contract is the same as the current implementation contract that the proxy is pointing to.
     * This function does not validate that the reference contract is the current implementation.
     *
     * @param proxyAddress The proxy address
     * @param newImplementationContractName Name of the new implementation contract to upgrade to, e.g. "MyContract.sol" or "MyContract.sol:MyContract" or artifact path relative to the project root directory
     * @param opts Common options. Note that the `useDefenderDeploy` option is always treated as `true` when called from this function.
     * @return Struct containing the proposal ID and URL for the upgrade proposal
     */
    function proposeUpgrade(
        address proxyAddress,
        string memory newImplementationContractName,
        Options memory opts
    ) internal returns (ProposeUpgradeResponse memory) {
        opts.defender.useDefenderDeploy = true;
        address proxyAdminAddress = Upgrades.getAdminAddress(proxyAddress);
        address newImplementationAddress = Upgrades.prepareUpgrade(newImplementationContractName, opts);
        return
            DefenderDeploy.proposeUpgrade(
                proxyAddress,
                proxyAdminAddress,
                newImplementationAddress,
                newImplementationContractName,
                opts
            );
    }
}

struct ProposeUpgradeResponse {
    string proposalId;
    string url;
}
