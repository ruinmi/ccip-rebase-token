// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
/**
 * @title Rebase Token
 * @author Guthrie Chu
 * @notice This is cross-chain rebase token that incentivises users to deposit into a vault
 * @notice The interst rate in the smart contract can only decrease
 * @notice Each user will have their own interst rate that is the global interest rate at the time of depositing
 */

contract RebaseToken is ERC20, Ownable, AccessControl {
    error RebaseToken_InterestRateCanOnlyDecrease();

    bytes32 private constant MINT_AND_BURN_ROLE = keccak256("MINT_AND_BURN_ROLE");
    uint256 private constant INTERST_RATE_PRECISION_FACTOR = 1e18;
    uint256 private _interestRate = 5e10;
    mapping(address => uint256) private _userInterestRate;
    mapping(address => uint256) private _userBalanceUpdateTimestamp;

    event InterestSet();

    constructor() ERC20("Rebase Token", "RBT") Ownable(msg.sender) {
    }

    /**
     * @notice Grants the MINT_AND_BURN_ROLE to an account
     * @param account The address to grant the role to
     */
    function grantMintAndBurnRole(address account) external onlyOwner {
        _grantRole(MINT_AND_BURN_ROLE, account);
    }

    /**
     * @notice Updates the global interest rate
     * @dev New rate must be strictly lower than the current one
     * @param interstRate The new global interest rate
     */
    function setInterestRate(uint256 interstRate) external onlyOwner {
        require(interstRate < _interestRate, RebaseToken_InterestRateCanOnlyDecrease());

        _interestRate = interstRate;
        emit InterestSet();
    }

    /**
     * @notice Returns the current balance of a user, including accrued interest
     * @param user The account to query
     */
    function balanceOf(address user) public view override returns (uint256) {
        return super.balanceOf(user) + _calculateAccumulatedInterestSinceLastUpdate(user);
    }

    /**
     * @notice Mints tokens to an account
     * @dev Also mints accrued interest before updating principal
     * @param to The recipient address
     * @param amount The amount of tokens to mint
     * @param interestRate The new interest rate to set
     */
    function mint(address to, uint256 amount, uint256 interestRate) external onlyRole(MINT_AND_BURN_ROLE) {
        _mintAccruedInterest(to);
        _userInterestRate[to] = interestRate;
        _mint(to, amount);
    }

    /**
     * @notice Burns tokens from an account
     * @dev If `amount` is set to max uint256, burns the entire balance
     * @param from The account whose tokens will be burned
     * @param amount The amount of tokens to burn
     */
    function burn(address from, uint256 amount) external onlyRole(MINT_AND_BURN_ROLE) {
        if (amount == type(uint256).max) {
            amount = balanceOf(from);
        }
        _mintAccruedInterest(from);
        _burn(from, amount);
    }

    /**
     * @notice Transfers tokens to another address
     * @dev Delegates to transferFrom with `msg.sender` as the source
     */
    function transfer(address to, uint256 amount) public override returns (bool) {
        uint256 toInterestRate = _userInterestRate[to];
        uint256 fromInterestRate = _userInterestRate[msg.sender];
        _mintAccruedInterest(msg.sender);
        _mintAccruedInterest(to);
        if (amount == type(uint256).max) {
            amount = balanceOf(msg.sender);
        }
        if (toInterestRate > fromInterestRate) {
            _userInterestRate[to] = fromInterestRate;
        }
        if (balanceOf(to) == 0) {
            _userInterestRate[to] = fromInterestRate;
        }
        return super.transfer(to, amount);
    }

    /**
     * @notice Transfers tokens between accounts
     * @dev Accrued interest is minted for both sender and receiver.
     *      The receiver inherits the lower interest rate if they had a higher one.
     */
    function transferFrom(address from, address to, uint256 amount) public override returns (bool) {
        uint256 toInterestRate = _userInterestRate[to];
        uint256 fromInterestRate = _userInterestRate[from];
        _mintAccruedInterest(from);
        _mintAccruedInterest(to);
        if (amount == type(uint256).max) {
            amount = balanceOf(from);
        }
        if (toInterestRate > fromInterestRate) {
            _userInterestRate[to] = fromInterestRate;
        }
        if (balanceOf(to) == 0) {
            _userInterestRate[to] = fromInterestRate;
        }
        return super.transferFrom(from, to, amount);
    }

    /////////////////////////////////
    //            Getters          //
    /////////////////////////////////
    function getInterestRate() external view returns (uint256) {
        return _interestRate;
    }

    function getUserInterestRate(address user) external view returns (uint256) {
        return _userInterestRate[user];
    }

    function getUserBalanceUpdateTimestamp(address user) external view returns (uint256) {
        return _userBalanceUpdateTimestamp[user];
    }

    function getPrincipal(address user) external view returns (uint256) {
        return super.balanceOf(user);
    }

    function getUserInterest(address user) external view returns (uint256) {
        return _calculateAccumulatedInterestSinceLastUpdate(user);
    }

    function getInterestRatePrecisionRate() external pure returns (uint256) {
        return INTERST_RATE_PRECISION_FACTOR;
    }

    function getMintAndBurnRole() external pure returns (bytes32) {
        return MINT_AND_BURN_ROLE;
    }

    ///////////////////////////////////
    //       Private Functions       //
    ///////////////////////////////////

    /**
     * @dev Mints accumulated interest to a user since their last balance update
     * @param user The account to update
     */
    function _mintAccruedInterest(address user) private {
        uint256 accumulatedInterest = _calculateAccumulatedInterestSinceLastUpdate(user);
        _userBalanceUpdateTimestamp[user] = block.timestamp;
        _mint(user, accumulatedInterest);
    }

    /**
     * @dev Calculates interest accumulated by a user since their last update
     * @param user The account to calculate for
     * @return accumulatedInterest The amount of interest accrued
     */
    function _calculateAccumulatedInterestSinceLastUpdate(address user)
        private
        view
        returns (uint256 accumulatedInterest)
    {
        uint256 principleBalance = super.balanceOf(user);
        uint256 interestRate = _userInterestRate[user];
        uint256 timeElapsed = block.timestamp - _userBalanceUpdateTimestamp[user];
        accumulatedInterest = principleBalance * interestRate * timeElapsed / INTERST_RATE_PRECISION_FACTOR;
    }
}
