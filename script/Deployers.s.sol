// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {Script} from "forge-std/Script.sol";
import {RebaseToken} from "src/RebaseToken.sol";
import {RebaseTokenPool} from "../src/RebaseTokenPool.sol";

contract DeployTokenAndPool is Script {
    function run() external returns (RebaseToken) {
        vm.startBroadcast();
        RebaseToken rebaseToken = new RebaseToken();
//        RebaseTokenPool pool = new RebaseTokenPool();
        vm.stopBroadcast();

        return rebaseToken;
    }
}
