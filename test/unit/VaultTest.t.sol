// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {RebaseToken} from "src/RebaseToken.sol";
import {IRebaseToken} from "src/interfaces/IRebaseToken.sol";
import {Vault} from "src/Vault.sol";
import {Test} from "forge-std/Test.sol";

contract VaultTest is Test {
    Vault public vault;
    RebaseToken public rbt;

    address public immutable OWNER = makeAddr("owner");
    address public immutable ADMIN = makeAddr("admin");
    address public immutable USER = makeAddr("user");
    uint256 public constant DEPOSIT_AMOUNT = 100 ether;

    function setUp() external {
        vm.startPrank(OWNER);
        rbt = new RebaseToken();
        vault = new Vault(IRebaseToken(address(rbt)));
        rbt.grantMintAndBurnRole(address(vault));

        vm.stopPrank();
    }

    function test_deposit() external {
        vm.deal(USER, DEPOSIT_AMOUNT);
        vm.prank(USER);
        vault.deposit{value: DEPOSIT_AMOUNT}();
    }

    function test_transfer() external {
        vm.deal(USER, DEPOSIT_AMOUNT);
        vm.prank(USER);
        (bool success,) = payable(address(vault)).call{value: DEPOSIT_AMOUNT}("");
        assertTrue(success);
    }

    function test_fallback() external {
        vm.deal(USER, DEPOSIT_AMOUNT);
        vm.prank(USER);
        (bool success,) = payable(address(vault)).call{value: DEPOSIT_AMOUNT}(bytes("random"));
        assertTrue(success);
    }

    function test_redeem() external {
        vm.deal(USER, DEPOSIT_AMOUNT);
        vm.prank(USER);
        vault.deposit{value: DEPOSIT_AMOUNT}();

        vm.prank(USER);
        vault.redeem(DEPOSIT_AMOUNT);
    }
}
