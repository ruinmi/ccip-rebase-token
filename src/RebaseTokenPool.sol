// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {TokenPool} from "@chainlink/local/lib/chainlink-ccip/chains/evm/contracts/pools/TokenPool.sol";
import {IERC20} from
    "@chainlink/local/lib/chainlink-evm/contracts/src/v0.8/vendor/openzeppelin-solidity/v4.8.3/contracts/token/ERC20/IERC20.sol";
import {IRebaseToken} from "src/interfaces/IRebaseToken.sol";
import {Pool} from "@chainlink/local/lib/chainlink-ccip/chains/evm/contracts/libraries/Pool.sol";

contract RebaseTokenPool is TokenPool {
    constructor(IERC20 token, address[] memory allowlist, address rmnProxy, address router)
        TokenPool(token, 18, allowlist, rmnProxy, router)
    {}

    function lockOrBurn(Pool.LockOrBurnInV1 calldata lockOrBurnIn)
        external
        returns (Pool.LockOrBurnOutV1 memory lockOrBurnOut)
    {
        _validateLockOrBurn(lockOrBurnIn);

        IRebaseToken rb = IRebaseToken(lockOrBurnIn.localToken);
        rb.burn(address(this), lockOrBurnIn.amount);
        lockOrBurnOut = Pool.LockOrBurnOutV1({
            destTokenAddress: getRemoteToken(lockOrBurnIn.remoteChainSelector),
            destPoolData: abi.encode(rb.getUserInterestRate(lockOrBurnIn.originalSender))
        });
    }

    function releaseOrMint(Pool.ReleaseOrMintInV1 calldata releaseOrMintIn)
        external
        returns (Pool.ReleaseOrMintOutV1 memory)
    {
        _validateReleaseOrMint(releaseOrMintIn);

        IRebaseToken rb = IRebaseToken(releaseOrMintIn.localToken);
        rb.mint(releaseOrMintIn.receiver, releaseOrMintIn.amount, abi.decode(releaseOrMintIn.sourcePoolData, (uint256)));
        return Pool.ReleaseOrMintOutV1({destinationAmount: releaseOrMintIn.amount});
    }
}
