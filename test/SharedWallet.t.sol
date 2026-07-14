// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.36;

import {Test} from "forge-std/Test.sol";
import {SharedWallet} from "../src/SharedWallet.sol";

contract TestSharedWallet is Test {
  function testConstructor(address [] memory _owners, uint16 _requiredApprovals) public {
    // I've got nothin so far..   
  }
}
