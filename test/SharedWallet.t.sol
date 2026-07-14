// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {SharedWallet} from "../src/SharedWallet.sol";

contract TestSharedWallet is Test {
  SharedWallet wallet;

  function setUp() public { 
    //wallet = new SharedWallet(); 
  }
}
