// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {Script} from "forge-std/Script.sol";
import {IRouterClient} from "@chainlink/local/lib/chainlink-ccip/chains/evm/contracts/interfaces/IRouterClient.sol";
import {CCIPLocalSimulatorFork} from "@chainlink/local/src/ccip/CCIPLocalSimulatorFork.sol";
import {Register} from "@chainlink/local/src/ccip/Register.sol";
import {Client} from "@chainlink/local/lib/chainlink-ccip/chains/evm/contracts/libraries/Client.sol";
import {IERC20} from
    "@chainlink/local/lib/chainlink-evm/contracts/src/v0.8/vendor/openzeppelin-solidity/v4.8.3/contracts/token/ERC20/IERC20.sol";

/*
 * @title A script to bridge tokens using CCIP
 * @notice This script uses Foundry's Script functionality to broadcast a transaction that bridges tokens
 *        from the local chain to a remote chain using Chainlink's CCIP protocol. It
 *        constructs the necessary message and handles token approvals and fee payments.
 * @param receiver The address on the remote chain to receive the tokens.
 * @param localToken The address of the token on the local chain to be bridged.
 * @param amount The amount of tokens to be bridged.
 * @param remoteChainSelector The chain selector (identifier) for the remote chain.
 */
contract BridgeTokens is Script {
    function run(address receiver, address localToken, uint256 amount, uint64 remoteChainSelector)
        external
        returns (bytes32 messageId)
    {
        CCIPLocalSimulatorFork simulator = new CCIPLocalSimulatorFork();
        Register.NetworkDetails memory network = simulator.getNetworkDetails(block.chainid);

        Client.EVMTokenAmount[] memory tokenAmounts = new Client.EVMTokenAmount[](1);
        tokenAmounts[0] = Client.EVMTokenAmount(localToken, amount);
        Client.EVM2AnyMessage memory message = Client.EVM2AnyMessage({
            receiver: abi.encode(receiver),
            data: "",
            tokenAmounts: tokenAmounts,
            feeToken: network.linkAddress,
            extraArgs: Client._argsToBytes(Client.EVMExtraArgsV1(100_000))
        });

        vm.startBroadcast();
        uint256 fee = IRouterClient(network.routerAddress).getFee(remoteChainSelector, message);
        IERC20(network.linkAddress).approve(network.routerAddress, fee);
        IERC20(localToken).approve(network.routerAddress, amount);
        messageId = IRouterClient(network.routerAddress).ccipSend(remoteChainSelector, message);
        vm.stopBroadcast();
    }
}
