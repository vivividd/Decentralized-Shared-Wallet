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
    uint16 _requiredApprovals) public {
      address [] memory emptyOwners = new address [](0);
      vm.expectRevert(SharedWallet.InvalidOwnersRequirement.selector);

      new SharedWallet(emptyOwners, _requiredApprovals);
  }
  
  function testZeroApprovals(
    address [] memory _owners
    ) public {
      
      vm.assume(_owners.length > 0);
      for(uint256 i = 0; i < _owners.length; i++) {
        vm.assume(_owners[i] != address(0)); 
      }

      vm.expectRevert(SharedWallet.InvalidApprovalRequirement.selector);

      new SharedWallet(_owners, 0);
  }

  function testLessOwnersThanApprovals(
    uint16 _requiredApprovals,
    address [] memory _owners
    ) public {
      
      vm.assume(_owners.length < _requiredApprovals);
      vm.assume(_requiredApprovals > 0);

      vm.assume(_owners.length > 0);
      for(uint256 i = 0; i < _owners.length; i++) {
        vm.assume(_owners[i] != address(0)); 
      }

      vm.expectRevert(SharedWallet.InvalidApprovalRequirement.selector);

      new SharedWallet(_owners, 0);
  }


  function testDuplicatedOwners(
    uint16 _requiredApprovals,
    address [] memory _owners
    ) public {
      
      vm.assume(_owners.length > 2);
      vm.assume(_requiredApprovals >= 2);
      vm.assume(_owners.length >= _requiredApprovals);

      for(uint256 i = 0; i < _owners.length; i++) {
        vm.assume(_owners[i] != address(0)); 
      }
      _owners[0] = _owners[1];
      vm.expectRevert(SharedWallet.InvalidOwnersRequirement.selector);

      new SharedWallet(_owners, _requiredApprovals);
  }
}
