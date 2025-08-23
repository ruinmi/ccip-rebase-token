// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {Script} from "forge-std/Script.sol";
import {TokenPool} from "@chainlink/local/lib/chainlink-ccip/chains/evm/contracts/pools/TokenPool.sol";
import {RateLimiter} from "@chainlink/local/lib/chainlink-ccip/chains/evm/contracts/libraries/RateLimiter.sol";

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
