// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {IRouterClient} from "@chainlink/local/lib/chainlink-ccip/chains/evm/contracts/interfaces/IRouterClient.sol";
import {CCIPLocalSimulatorFork} from "@chainlink/local/src/ccip/CCIPLocalSimulatorFork.sol";
import {Register} from "@chainlink/local/src/ccip/Register.sol";
import {RebaseTokenPool} from "src/RebaseTokenPool.sol";
import {IERC20} from
    "@chainlink/local/lib/chainlink-evm/contracts/src/v0.8/vendor/openzeppelin-solidity/v4.8.3/contracts/token/ERC20/IERC20.sol";
import {RebaseToken} from "src/RebaseToken.sol";
import {CCIPUtils} from "test/integration/CCIPUtils.sol";
import {Test, console} from "forge-std/Test.sol";
import {ITokenAdminRegistry} from
    "@chainlink/local/lib/chainlink-ccip/chains/evm/contracts/interfaces/ITokenAdminRegistry.sol";
import {RegistryModuleOwnerCustom} from
    "@chainlink/local/lib/chainlink-ccip/chains/evm/contracts/tokenAdminRegistry/RegistryModuleOwnerCustom.sol";
import {Client} from "@chainlink/local/lib/chainlink-ccip/chains/evm/contracts/libraries/Client.sol";

/*
 * @title A Foundry test for cross-chain transfers using RebaseToken and RebaseTokenPool
 * @notice This test sets up two forks (Sepolia and Arbitrum Sepolia), deploys RebaseToken and RebaseTokenPool on each,
 *         configures them for cross-chain transfers, and tests sending tokens between the two chains using CCIP.
 * @dev The test uses CCIPLocalSimulatorFork to simulate the CCIP environment and route messages between the two forks.
 */
contract CrossChainTest is Test {
    uint256 public sepForkId;
    uint256 public arbSepForkId;
    address public owner = makeAddr("owner");
    address public jiating = makeAddr("jiating");
    address public feiyu = makeAddr("feiyu");
    uint256 public constant INITIAL_BALANCE = 100 ether;
    uint256 public constant LINK_BALANCE = 100 ether;
    uint256 public constant SEND_AMOUNT = 5 ether;

    RebaseToken public sepToken;
    RebaseToken public arbSepToken;
    RebaseTokenPool public sepPool;
    RebaseTokenPool public arbSepPool;
    IRouterClient public sepRouter;
    IRouterClient public arbSepRouter;
    Register.NetworkDetails public sepDetails;
    Register.NetworkDetails public arbSepDetails;
    CCIPLocalSimulatorFork public simulator;

    function setUp() external {
        sepForkId = vm.createSelectFork("sepolia");
        arbSepForkId = vm.createFork("arb-sepolia");
        address[] memory allowlist = new address[](0);

        simulator = new CCIPLocalSimulatorFork();
        vm.makePersistent(address(simulator));
        sepDetails = simulator.getNetworkDetails(block.chainid);
        vm.selectFork(arbSepForkId);
        arbSepDetails = simulator.getNetworkDetails(block.chainid);
        vm.selectFork(sepForkId);

        // 1. set up src chain
        vm.startPrank(owner);
        sepToken = new RebaseToken();
        sepPool = new RebaseTokenPool(
            IERC20(address(sepToken)), allowlist, sepDetails.rmnProxyAddress, sepDetails.routerAddress
        );
        _setUpAdminAndPool(
            sepDetails.tokenAdminRegistryAddress,
            sepDetails.registryModuleOwnerCustomAddress,
            address(sepToken),
            address(sepPool)
        );
        sepToken.grantMintAndBurnRole(address(sepPool));
        sepToken.grantMintAndBurnRole(address(owner));
        sepToken.mint(jiating, INITIAL_BALANCE, sepToken.getInterestRate());
        sepToken.mint(feiyu, INITIAL_BALANCE, sepToken.getInterestRate());
        simulator.requestLinkFromFaucet(jiating, LINK_BALANCE);
        simulator.requestLinkFromFaucet(feiyu, LINK_BALANCE);
        vm.stopPrank();

        vm.selectFork(arbSepForkId);

        // 2. set up dest chain
        vm.startPrank(owner);
        arbSepToken = new RebaseToken();
        arbSepPool = new RebaseTokenPool(
            IERC20(address(arbSepToken)), allowlist, arbSepDetails.rmnProxyAddress, arbSepDetails.routerAddress
        );
        _setUpAdminAndPool(
            arbSepDetails.tokenAdminRegistryAddress,
            arbSepDetails.registryModuleOwnerCustomAddress,
            address(arbSepToken),
            address(arbSepPool)
        );
        arbSepToken.grantMintAndBurnRole(address(arbSepPool));
        arbSepToken.grantMintAndBurnRole(address(owner));
        arbSepToken.mint(jiating, INITIAL_BALANCE, arbSepToken.getInterestRate());
        arbSepToken.mint(feiyu, INITIAL_BALANCE, arbSepToken.getInterestRate());
        simulator.requestLinkFromFaucet(jiating, LINK_BALANCE);
        simulator.requestLinkFromFaucet(feiyu, LINK_BALANCE);
        vm.stopPrank();

        // configure pools
        vm.startPrank(owner);
        arbSepPool.applyChainUpdates(
            new uint64[](0), CCIPUtils.composeUpdates(address(sepToken), address(sepPool), sepDetails.chainSelector)
        );
        vm.selectFork(sepForkId);
        sepPool.applyChainUpdates(
            new uint64[](0),
            CCIPUtils.composeUpdates(address(arbSepToken), address(arbSepPool), arbSepDetails.chainSelector)
        );
        vm.stopPrank();

        sepRouter = IRouterClient(sepDetails.routerAddress);
        arbSepRouter = IRouterClient(arbSepDetails.routerAddress);
    }

    function _setUpAdminAndPool(address registry, address module, address token, address pool) private {
        RegistryModuleOwnerCustom registryModule = RegistryModuleOwnerCustom(module);
        ITokenAdminRegistry adminRegistry = ITokenAdminRegistry(registry);
        registryModule.registerAdminViaOwner(token);
        adminRegistry.acceptAdminRole(token);
        adminRegistry.setPool(token, pool);
    }

    function routeMessage(uint256 localFork, uint256 remoteFork) public {
        vm.selectFork(localFork);
        simulator.switchChainAndRouteMessage(remoteFork);
        vm.selectFork(remoteFork);
    }

    function bridgeTokens(
        uint256 localFork,
        uint256 remoteFork,
        address sender,
        address receiver,
        uint256 amount,
        address localRouter,
        uint64 remoteChainSelector,
        address localLinkAddress,
        address localTokenAddress,
        address remoteTokenAddress
    ) public {
        vm.selectFork(localFork);
        uint256 startingBalance = RebaseToken(localTokenAddress).balanceOf(sender);

        Client.EVM2AnyMessage memory evm2AnyMessage =
            CCIPUtils.buildCCIPMessage(receiver, localTokenAddress, amount, localLinkAddress);
        uint256 fee = IRouterClient(localRouter).getFee(remoteChainSelector, evm2AnyMessage);

        vm.startPrank(sender);
        IERC20(localLinkAddress).approve(localRouter, fee);
        RebaseToken(localTokenAddress).approve(localRouter, amount);
        IRouterClient(localRouter).ccipSend(remoteChainSelector, evm2AnyMessage);
        vm.stopPrank();

        uint256 endingBalance = RebaseToken(localTokenAddress).balanceOf(sender);

        vm.warp(block.timestamp + 20 minutes);
        vm.selectFork(remoteFork);
        uint256 remoteBalanceBefore = RebaseToken(remoteTokenAddress).balanceOf(receiver);
        routeMessage(localFork, remoteFork);
        uint256 remoteBalanceAfter = RebaseToken(remoteTokenAddress).balanceOf(receiver);

        assertEq(remoteBalanceAfter - remoteBalanceBefore, amount);
        assertEq(endingBalance + amount, startingBalance);
    }

    function test_crossSend() external {
        bridgeTokens(
            sepForkId,
            arbSepForkId,
            jiating,
            feiyu,
            SEND_AMOUNT,
            address(sepRouter),
            arbSepDetails.chainSelector,
            sepDetails.linkAddress,
            address(sepToken),
            address(arbSepToken)
        );

        bridgeTokens(
            arbSepForkId,
            sepForkId,
            feiyu,
            jiating,
            SEND_AMOUNT,
            address(arbSepRouter),
            sepDetails.chainSelector,
            arbSepDetails.linkAddress,
            address(arbSepToken),
            address(sepToken)
        );
    }
}
