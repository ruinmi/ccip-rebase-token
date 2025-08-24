// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

interface IRebaseToken {
    function mint(address to, uint256 amount, uint256 interestRate) external;
    function burn(address from, uint256 amount) external;
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function getInterestRate() external view returns (uint256);
    function getUserInterestRate(address user) external view returns (uint256);
    function grantMintAndBurnRole(address account) external;
}
