// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {SharedWallet} from "../src/SharedWallet.sol";

contract TestSharedWallet is Test {
  
  // CONSTRUCTOR testing

  function testWrongOwnerAddress(
    address [] memory _owners, 
    uint16 _requiredApprovals) public {
      vm.assume(_owners.length >= _requiredApprovals);
      vm.assume(_requiredApprovals > 0);

      _owners[0] = address(0);
      for(uint256 i = 1; i < _owners.length; i++) {
        vm.assume(_owners[i] != address(0)); 
      }
    
      vm.expectRevert(SharedWallet.InvalidOwnersRequirement.selector);

      new SharedWallet(_owners, _requiredApprovals);
    }

  function testZeroOwners(
    address [] memory _owners, 
    uint16 _requiredApprovals) public {
      vm.expectRevert(SharedWallet.InvalidOwnersRequirement.selector);

      address [] emptyOwners = 
      new SharedWallet(, _requiredApprovals);
  }
}
