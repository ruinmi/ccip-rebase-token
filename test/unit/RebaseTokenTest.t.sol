// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {RebaseToken} from "src/RebaseToken.sol";
import {Test, console} from "forge-std/Test.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract RebaseTokenTest is Test {
    RebaseToken public rbt;

    address public immutable OWNER = makeAddr("owner");
    address public immutable ADMIN = makeAddr("admin");
    uint256 public constant MINT_AMOUNT = 100 ether;

    modifier mint(address user, uint256 amount) {
        vm.prank(OWNER);
        rbt.grantMintAndBurnRole(ADMIN);

        vm.prank(ADMIN);
        rbt.mint(user, amount, rbt.getInterestRate());
        _;
    }

    function setUp() external {
        vm.prank(OWNER);
        rbt = new RebaseToken();
    }

    ///////////////////////////////////
    //        setInterestRate        //
    ///////////////////////////////////
    function test_setInterestRate() external {
        uint256 startingInterestRate = rbt.getInterestRate();

        vm.prank(OWNER);
        rbt.setInterestRate(4e10);

        assert(rbt.getInterestRate() < startingInterestRate);
        assert(rbt.getInterestRate() == 4e10);
    }

    function test_revertIfSetInterestRateNotByOwner() external {
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, address(this)));
        rbt.setInterestRate(4e10);
    }

    function test_revertIfInterestRateIncrease() external {
        vm.prank(OWNER);
        vm.expectRevert(RebaseToken.RebaseToken_InterestRateCanOnlyDecrease.selector);
        rbt.setInterestRate(6e10);
    }

    /////////////////////////////
    //     MintAndBurnRole     //
    /////////////////////////////
    function test_grantMintAndBurnRole() external {
        vm.prank(OWNER);
        rbt.grantMintAndBurnRole(ADMIN);

        vm.prank(ADMIN);
        rbt.mint(OWNER, MINT_AMOUNT, rbt.getInterestRate());
    }

    function test_revertIfNotOwnerGrantMintAndBurnRole() external {
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, address(this)));
        rbt.grantMintAndBurnRole(ADMIN);
    }

    ///////////////////////////////////
    //          mint & burn          //
    ///////////////////////////////////
    function test_mint() external mint(OWNER, MINT_AMOUNT) {
        assert(rbt.balanceOf(OWNER) == MINT_AMOUNT);
    }

    function test_mintAndMintInterestAutomatically() external mint(OWNER, MINT_AMOUNT) {
        vm.warp(1 hours);
        uint256 interest = rbt.getUserInterest(OWNER);

        vm.prank(ADMIN);
        rbt.mint(OWNER, MINT_AMOUNT, rbt.getInterestRate());

        assert(rbt.getPrincipal(OWNER) == 2 * MINT_AMOUNT + interest);
    }

    function test_mintUpdateInterestRate() external mint(OWNER, MINT_AMOUNT) {
        vm.prank(OWNER);
        rbt.setInterestRate(4e10);

        vm.prank(ADMIN);
        rbt.mint(OWNER, MINT_AMOUNT, rbt.getInterestRate());

        assert(rbt.getUserInterestRate(OWNER) == 4e10);
    }

    function test_burn() external mint(OWNER, MINT_AMOUNT) {
        vm.prank(ADMIN);
        rbt.burn(OWNER, MINT_AMOUNT);

        assert(rbt.balanceOf(OWNER) == 0);
    }

    function test_burnAndMintInterestAutomatically() external mint(OWNER, MINT_AMOUNT) {
        vm.warp(1 hours);
        uint256 interest = rbt.getUserInterest(OWNER);

        vm.prank(ADMIN);
        rbt.burn(OWNER, MINT_AMOUNT);

        assert(rbt.getPrincipal(OWNER) == interest);
    }

    function test_burnAll() external mint(OWNER, MINT_AMOUNT) {
        vm.prank(ADMIN);
        rbt.burn(OWNER, type(uint256).max);

        assert(rbt.balanceOf(OWNER) == 0);
    }

    ///////////////////////////////
    //        Interest           //
    ///////////////////////////////
    function test_balanceOf() external mint(OWNER, MINT_AMOUNT) {
        uint256 interestRate = rbt.getUserInterestRate(OWNER);
        uint256 principal = rbt.getPrincipal(OWNER);
        uint256 precision = rbt.getInterestRatePrecisionRate();
        uint256 expectedBalance = principal * interestRate * 1 / precision + principal;
        vm.warp(block.timestamp + 1);

        uint256 balance = rbt.balanceOf(OWNER);

        console.log("interestRate   :", interestRate);
        console.log("principal      :", principal);
        console.log("expectedBalance:", expectedBalance);
        console.log("balance        :", balance);

        assert(balance == expectedBalance);
        assert(balance > principal);
    }

    ///////////////////////////////////
    //           Transfer            //
    ///////////////////////////////////
    function test_transfer() external mint(OWNER, MINT_AMOUNT) {
        vm.prank(OWNER);
        bool success = rbt.transfer(ADMIN, MINT_AMOUNT);

        assert(success == true);
        assert(rbt.getPrincipal(ADMIN) == MINT_AMOUNT);
        assert(rbt.getUserInterestRate(ADMIN) == rbt.getInterestRate());
    }

    function test_transferAutoMintBothInterest() external mint(OWNER, MINT_AMOUNT) mint(ADMIN, MINT_AMOUNT) {
        vm.warp(block.timestamp + 1 hours);
        uint256 userInterest = rbt.getUserInterest(OWNER);

        vm.prank(OWNER);
        bool success = rbt.transfer(ADMIN, MINT_AMOUNT);

        assert(success == true);
        assert(rbt.getPrincipal(OWNER) == userInterest);
        assert(rbt.getPrincipal(ADMIN) == 2 * MINT_AMOUNT + userInterest);
    }

    function test_transferInheritsLowerInterestRate() external mint(OWNER, MINT_AMOUNT) {
        vm.prank(OWNER);
        rbt.setInterestRate(4e10);

        vm.prank(ADMIN);
        rbt.mint(ADMIN, MINT_AMOUNT, rbt.getInterestRate());

        vm.prank(ADMIN);
        bool success = rbt.transfer(OWNER, MINT_AMOUNT);

        assert(success == true);
        assert(rbt.getPrincipal(OWNER) == 2 * MINT_AMOUNT);
        assert(rbt.getUserInterestRate(OWNER) == 4e10);
    }

    function test_transferAmountAll() external mint(OWNER, MINT_AMOUNT) {
        vm.prank(OWNER);
        bool success = rbt.transfer(ADMIN, type(uint256).max);

        assert(success == true);
        assert(rbt.getPrincipal(ADMIN) == MINT_AMOUNT);
        assert(rbt.getUserInterestRate(ADMIN) == rbt.getInterestRate());
    }

    ///////////////////////////////////
    //        Transfer From          //
    ///////////////////////////////////
    function test_transferFrom() external mint(OWNER, MINT_AMOUNT) {
        vm.prank(OWNER);
        rbt.approve(OWNER, MINT_AMOUNT);
        vm.prank(OWNER);
        bool success = rbt.transferFrom(OWNER, ADMIN, MINT_AMOUNT);

        assert(success == true);
        assert(rbt.getPrincipal(ADMIN) == MINT_AMOUNT);
        assert(rbt.getUserInterestRate(ADMIN) == rbt.getInterestRate());
    }

    function test_transferFromAutoMintBothInterest() external mint(OWNER, MINT_AMOUNT) mint(ADMIN, MINT_AMOUNT) {
        vm.warp(block.timestamp + 1 hours);
        uint256 userInterest = rbt.getUserInterest(OWNER);

        vm.prank(OWNER);
        rbt.approve(OWNER, MINT_AMOUNT);
        vm.prank(OWNER);
        bool success = rbt.transferFrom(OWNER, ADMIN, MINT_AMOUNT);

        assert(success == true);
        assert(rbt.getPrincipal(OWNER) == userInterest);
        assert(rbt.getPrincipal(ADMIN) == 2 * MINT_AMOUNT + userInterest);
    }

    function test_transferFromInheritsLowerInterestRate() external mint(OWNER, MINT_AMOUNT) {
        vm.prank(OWNER);
        rbt.setInterestRate(4e10);

        vm.prank(ADMIN);
        rbt.approve(ADMIN, MINT_AMOUNT);
        vm.prank(ADMIN);
        rbt.mint(ADMIN, MINT_AMOUNT, rbt.getInterestRate());

        vm.prank(ADMIN);
        bool success = rbt.transferFrom(ADMIN, OWNER, MINT_AMOUNT);

        assert(success == true);
        assert(rbt.getPrincipal(OWNER) == 2 * MINT_AMOUNT);
        assert(rbt.getUserInterestRate(OWNER) == 4e10);
    }

    function test_transferFromAmountAll() external mint(OWNER, MINT_AMOUNT) {
        vm.prank(OWNER);
        rbt.approve(OWNER, MINT_AMOUNT);
        vm.prank(OWNER);
        bool success = rbt.transferFrom(OWNER, ADMIN, type(uint256).max);

        assert(success == true);
        assert(rbt.getPrincipal(ADMIN) == MINT_AMOUNT);
        assert(rbt.getUserInterestRate(ADMIN) == rbt.getInterestRate());
    }

    /////////////////////////////
    //       Getters           //
    /////////////////////////////

    function test_getMintAndBurnRole() external view {
        assert(rbt.getMintAndBurnRole() == keccak256("MINT_AND_BURN_ROLE"));
    }

    function test_getUserBalanceUpdateTimestamp() external mint(OWNER, MINT_AMOUNT) {
        assert(rbt.getUserBalanceUpdateTimestamp(OWNER) == block.timestamp);
    }
}
