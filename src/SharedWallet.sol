// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

contract SharedWallet{
  address [] public owners; 
  uint16 public requiredApprovals; 
  mapping(address => bool) public isOwner;
  
  error InvalidOwnersRequirement();
  error InvalidApprovalRequirement();

  constructor (address [] memory _owners, uint16 _requiredApprovals) {
    if(_owners.length == 0) { revert InvalidOwnersRequirement(); }
  
    if (
      _owners.length < _requiredApprovals ||
      _requiredApprovals <= 0
    ) { revert InvalidApprovalRequirement(); }

    for (uint256 i = 0; i < _owners.length; i++) {
      address owner = _owners[i];
      
      if (owner == address(0)) {revert InvalidOwnersRequirement(); }

      if(isOwner[owner]) { revert InvalidOwnersRequirement(); }
      
      isOwner[owner] = true;
      owners.push(owner);
    }

    requiredApprovals = _requiredApprovals;
  }

}
