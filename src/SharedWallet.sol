// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

contract SharedWallet{
  address [] public owners; 
  uint16 public requiredApprovals; 
  mapping(address => bool) public isOwner;

  constructor (address [] memory _owners, uint16 _requiredApprovals) {
    require(_owners.length> 0, "At least one owner must exist. Currently - 0.");

    require (
      _owners.length >= _requiredApprovals &&
      _requiredApprovals > 0, 
      "Invalid Approval Requirement."
    );

    for (uint256 i = 0; i < _owners.length; i++) {
      address owner = _owners[i];

      require(owner != address(0), "Invalid Owner Address.");
      require(!isOwner[owner], "Duplicated Owner."); // Check if the address is already added.
      
      isOwner[owner] = true;
      owners.push(owner);
    }

    requiredApprovals = _requiredApprovals;
  }

}
