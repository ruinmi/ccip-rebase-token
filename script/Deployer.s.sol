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

contract TokenAndPoolDeployer is Script {
    function run() external returns (RebaseToken, RebaseTokenPool) {
        CCIPLocalSimulatorFork simulator = new CCIPLocalSimulatorFork();
        Register.NetworkDetails memory network = simulator.getNetworkDetails(block.chainid);
        address[] memory allowlist = new address[](0);

        vm.startBroadcast();
        RebaseToken rebaseToken = new RebaseToken();
        RebaseTokenPool pool =
            new RebaseTokenPool(IERC20(address(rebaseToken)), allowlist, network.rmnProxyAddress, network.routerAddress);
        RegistryModuleOwnerCustom(network.registryModuleOwnerCustomAddress).registerAdminViaOwner(address(rebaseToken));
        ITokenAdminRegistry(network.tokenAdminRegistryAddress).acceptAdminRole(address(rebaseToken));
        ITokenAdminRegistry(network.tokenAdminRegistryAddress).setPool(address(rebaseToken), address(pool));
        rebaseToken.grantMintAndBurnRole(address(pool));
        vm.stopBroadcast();

        return (rebaseToken, pool);
    }
}

contract VaultDeployer is Script {
    function run(IRebaseToken token) external returns (Vault) {
        vm.startBroadcast();
        Vault vault = new Vault(token);
        vm.stopBroadcast();

        return vault;
    }
}
