// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {TokenPool} from "@chainlink/local/lib/chainlink-ccip/chains/evm/contracts/pools/TokenPool.sol";
import {RateLimiter} from "@chainlink/local/lib/chainlink-ccip/chains/evm/contracts/libraries/RateLimiter.sol";
import {Client} from "@chainlink/local/lib/chainlink-ccip/chains/evm/contracts/libraries/Client.sol";

/*
 * @title CCIPUtils
 * @notice A utility library for composing CCIP messages and chain updates for TokenPools.
 * @dev This library provides functions to create chain updates for TokenPools and to build CCIP messages
 *      for cross-chain token transfers. It simplifies the process of configuring TokenPools and sending
 *      messages across different chains using Chainlink's CCIP.
 */
library CCIPUtils {
    function composeUpdates(address token, address pool, uint64 chainSelector)
        external
        pure
        returns (TokenPool.ChainUpdate[] memory ret)
    {
        ret = new TokenPool.ChainUpdate[](1);
        bytes[] memory destPoolAddresses = new bytes[](1);
        destPoolAddresses[0] = abi.encode(pool);
        TokenPool.ChainUpdate memory srcUpdate = TokenPool.ChainUpdate({
            remoteChainSelector: chainSelector,
            remotePoolAddresses: destPoolAddresses,
            remoteTokenAddress: abi.encode(token),
            outboundRateLimiterConfig: RateLimiter.Config({isEnabled: true, capacity: 100 ether, rate: 10 ether}),
            inboundRateLimiterConfig: RateLimiter.Config({isEnabled: true, capacity: 100 ether, rate: 10 ether})
        });

        ret[0] = srcUpdate;
    }

    function buildCCIPMessage(address receiver, address token, uint256 amount, address _feeTokenAddress)
        external
        pure
        returns (Client.EVM2AnyMessage memory message)
    {
        Client.EVMTokenAmount[] memory amounts = new Client.EVMTokenAmount[](1);
        amounts[0] = Client.EVMTokenAmount({token: address(token), amount: amount});
        message = Client.EVM2AnyMessage({
            receiver: abi.encode(receiver),
            data: "",
            tokenAmounts: amounts,
            feeToken: _feeTokenAddress,
            extraArgs: ""
        });
    }
}
