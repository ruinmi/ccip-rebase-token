// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {Script} from "forge-std/Script.sol";
import {TokenPool} from "@chainlink/local/lib/chainlink-ccip/chains/evm/contracts/pools/TokenPool.sol";
import {RateLimiter} from "@chainlink/local/lib/chainlink-ccip/chains/evm/contracts/libraries/RateLimiter.sol";

/*
 * @title ConfigurePool
 * @notice A script to configure a TokenPool with a remote token and pool address.
 * @dev This script uses Foundry's Script functionality to broadcast a transaction that configures
 *      the specified TokenPool contract with details about a remote chain, including the remote token
 *      address and remote pool address. It also sets up rate limiting configurations for inbound and
 *      outbound transfers.
 * @param localPool The address of the local TokenPool contract to be configured.
 * @param remoteToken The address of the token on the remote chain.
 * @param remotePool The address of the TokenPool on the remote chain.
 * @param remoteChainSelector The chain selector (identifier) for the remote chain.
 */
contract ConfigurePool is Script {
    function run(address localPool, address remoteToken, address remotePool, uint64 remoteChainSelector) external {
        TokenPool.ChainUpdate[] memory chainsToAdd = new TokenPool.ChainUpdate[](1);
        bytes[] memory remotePoolAddresses = new bytes[](1);
        remotePoolAddresses[0] = abi.encode(remotePool);
        chainsToAdd[0] = TokenPool.ChainUpdate({
            remoteChainSelector: remoteChainSelector,
            remotePoolAddresses: remotePoolAddresses,
            remoteTokenAddress: abi.encode(remoteToken),
            outboundRateLimiterConfig: RateLimiter.Config(false, 0, 0),
            inboundRateLimiterConfig: RateLimiter.Config(false, 0, 0)
        });
        uint64[] memory remoteChainSelectorsToRemove = new uint64[](0);

        vm.startBroadcast();
        TokenPool(localPool).applyChainUpdates(remoteChainSelectorsToRemove, chainsToAdd);
        vm.stopBroadcast();
    }
}
