// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {console2} from "forge-std/console2.sol";
import {SharedWallet} from "../src/SharedWallet.sol";

contract Deploy is Script {
    function run() external returns (SharedWallet wallet) {
        address[] memory owners = vm.envAddress("OWNERS", ",");
        uint256 requiredApprovalsValue = vm.envUint("REQUIRED_APPROVALS");

        require(owners.length > 0, "OWNERS must not be empty");
        require(requiredApprovalsValue > 0, "REQUIRED_APPROVALS must be greater than zero");
        require(requiredApprovalsValue <= owners.length, "REQUIRED_APPROVALS exceeds owner count");
        require(requiredApprovalsValue <= type(uint16).max, "REQUIRED_APPROVALS exceeds uint16 max");

        vm.startBroadcast();
        // forge-lint: disable-next-line(unsafe-typecast): bounded above by uint16.max above.
        wallet = new SharedWallet(owners, uint16(requiredApprovalsValue));
        vm.stopBroadcast();

        console2.log("SharedWallet deployed at:", address(wallet));
    }
}
