// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {Script} from "forge-std/Script.sol";
import {CCIPLocalSimulatorFork} from "@chainlink/local/src/ccip/CCIPLocalSimulatorFork.sol";
import {RebaseTokenPool} from "../src/RebaseTokenPool.sol";
import {RebaseToken} from "src/RebaseToken.sol";
import {IRebaseToken} from "src/interfaces/IRebaseToken.sol";
import {Register} from "@chainlink/local/src/ccip/Register.sol";
import {RegistryModuleOwnerCustom} from
    "@chainlink/local/lib/chainlink-ccip/chains/evm/contracts/tokenAdminRegistry/RegistryModuleOwnerCustom.sol";
import {ITokenAdminRegistry} from
    "@chainlink/local/lib/chainlink-ccip/chains/evm/contracts/interfaces/ITokenAdminRegistry.sol";
import {Vault} from "../src/Vault.sol";
import {IERC20} from
    "@chainlink/local/lib/chainlink-evm/contracts/src/v0.8/vendor/openzeppelin-solidity/v4.8.3/contracts/token/ERC20/IERC20.sol";

/*
 * @title A script to deploy RebaseToken and RebaseTokenPool using Foundry's Script functionality
 * @notice This script deploys a new instance of RebaseToken and RebaseTokenPool, sets up the necessary admin roles,
 *         and configures the token pool with the appropriate parameters for cross-chain functionality.
 * @dev The script uses CCIPLocalSimulatorFork to get network details for the current chain.
 */
contract TokenAndPoolDeployer is Script {
    function run() external returns (RebaseToken rebaseToken, RebaseTokenPool pool) {
        CCIPLocalSimulatorFork simulator = new CCIPLocalSimulatorFork();
        Register.NetworkDetails memory network = simulator.getNetworkDetails(block.chainid);
        address[] memory allowlist = new address[](0);

        vm.startBroadcast();
        rebaseToken = new RebaseToken();
        pool = new RebaseTokenPool(IERC20(address(rebaseToken)), allowlist, network.rmnProxyAddress, network.routerAddress);
        RegistryModuleOwnerCustom(network.registryModuleOwnerCustomAddress).registerAdminViaOwner(address(rebaseToken));
        ITokenAdminRegistry(network.tokenAdminRegistryAddress).acceptAdminRole(address(rebaseToken));
        ITokenAdminRegistry(network.tokenAdminRegistryAddress).setPool(address(rebaseToken), address(pool));
        rebaseToken.grantMintAndBurnRole(address(pool));
        vm.stopBroadcast();
    }
}

contract VaultDeployer is Script {
    function run(address token) external returns (Vault vault) {
        vm.startBroadcast();
        vault = new Vault(IRebaseToken(token));
        IRebaseToken(token).grantMintAndBurnRole(address(vault));
        vm.stopBroadcast();
    }
}
