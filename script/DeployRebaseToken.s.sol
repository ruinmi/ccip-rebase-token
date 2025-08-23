// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {Script} from "forge-std/Script.sol";
import {RebaseToken} from "src/RebaseToken.sol";

contract DeployRebaseToken is Script {
    function run() external returns (RebaseToken) {
        vm.startBroadcast();
        RebaseToken rebaseToken = new RebaseToken();
        vm.stopBroadcast();

        return rebaseToken;
    }
}
