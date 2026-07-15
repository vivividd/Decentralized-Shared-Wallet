// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {SharedWallet} from "../src/SharedWallet.sol";

contract TestSharedWallet is Test {
 
  function testZeroApprovals(
    address [] memory _owners, 
    uint16 _requiredApprovals
  ) public {
    vm.assume(_requiredApprovals == 0);
    vm.assume(_owners.length > 0);
    vm.assume(_owners.length >= _requiredApprovals);
    
    for(uint256 i = 0; i < _owners.length; i++) {
      vm.assume(_owners[i] != address(0));
    }

    vm.expectRevert("Invalid Approval Requirement.");
    
    SharedWallet wallet = new SharedWallet(_owners, _requiredApprovals);
  }

}
