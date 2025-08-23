// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {IRebaseToken} from "src/interfaces/IRebaseToken.sol";

contract Vault {
    error Vault_RedeemFailed();

    IRebaseToken private immutable REBASE_TOKEN;

    event Deposit(address indexed user, uint256 amount);
    event Redeem(address indexed user, uint256 amount);

    constructor(IRebaseToken rebaseToken) {
        REBASE_TOKEN = rebaseToken;
    }

    receive() external payable {
        deposit();
    }

    fallback() external payable {
        deposit();
    }

    /**
     * @notice Allows users to deposit Ether into the vault
     * @dev Users will receive Rebase Tokens in return, which represent their share in the
     * vault's assets. The amount of Rebase Tokens minted is equal to the Ether deposited.
     */
    function deposit() public payable {
        REBASE_TOKEN.mint(msg.sender, msg.value, REBASE_TOKEN.getInterestRate());
        emit Deposit(msg.sender, msg.value);
    }

    /**
     * @notice Allows users to redeem their Rebase Tokens for Ether
     * @dev Users can burn their Rebase Tokens to receive the equivalent amount of Ether.
     * The transaction will revert if the transfer of Ether fails.
     * @param amount The amount of Rebase Tokens to redeem
     */
    function redeem(uint256 amount) external {
        REBASE_TOKEN.burn(msg.sender, amount);
        (bool success,) = payable(msg.sender).call{value: amount}("");
        require(success, Vault_RedeemFailed());
        emit Redeem(msg.sender, amount);
    }
}
