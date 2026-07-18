// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {SharedWallet} from "../src/SharedWallet.sol";

contract RevertingTarget {
    fallback() external payable {
        revert();
    }
}

contract TestSharedWallet is Test {
    address owner1 = address(0x1);
    address owner2 = address(0x2);
    address owner3 = address(0x3);
    address recipient = address(0x4);
    SharedWallet wallet;

    function setUp() public {
        address[] memory walletOwners = new address[](3);
        walletOwners[0] = owner1;
        walletOwners[1] = owner2;
        walletOwners[2] = owner3;
        wallet = new SharedWallet(walletOwners, 2);
        vm.deal(address(wallet), 10 ether);
    }

    // CONSTRUCTOR testing

    function testWrongOwnerAddress(address[] memory _owners, uint16 _requiredApprovals) public {
        vm.assume(_owners.length >= _requiredApprovals);
        vm.assume(_requiredApprovals > 0);

        _owners[0] = address(0);
        for (uint256 i = 1; i < _owners.length; i++) {
            vm.assume(_owners[i] != address(0));
        }

        vm.expectRevert(SharedWallet.InvalidOwnersRequirement.selector);

        new SharedWallet(_owners, _requiredApprovals);
    }

    function testZeroOwners(uint16 _requiredApprovals) public {
        address[] memory emptyOwners = new address[](0);
        vm.expectRevert(SharedWallet.InvalidOwnersRequirement.selector);

        new SharedWallet(emptyOwners, _requiredApprovals);
    }

    function testZeroApprovals(address[] memory _owners) public {
        vm.assume(_owners.length > 0);
        for (uint256 i = 0; i < _owners.length; i++) {
            vm.assume(_owners[i] != address(0));
        }

        vm.expectRevert(SharedWallet.InvalidApprovalRequirement.selector);

        new SharedWallet(_owners, 0);
    }

    function testLessOwnersThanApprovals(uint16 _requiredApprovals, address[] memory _owners) public {
        vm.assume(_owners.length < _requiredApprovals);
        vm.assume(_requiredApprovals > _owners.length);

        vm.assume(_owners.length > 0);
        for (uint256 i = 0; i < _owners.length; i++) {
            vm.assume(_owners[i] != address(0));
        }

        vm.expectRevert(SharedWallet.InvalidApprovalRequirement.selector);

        new SharedWallet(_owners, _requiredApprovals);
    }

    function testDuplicatedOwners(uint16 _requiredApprovals, address[] memory _owners) public {
        vm.assume(_owners.length > 2);
        vm.assume(_requiredApprovals >= 2);
        vm.assume(_owners.length >= _requiredApprovals);

        for (uint256 i = 0; i < _owners.length; i++) {
            vm.assume(_owners[i] != address(0));
        }
        _owners[0] = _owners[1];
        vm.expectRevert(SharedWallet.InvalidOwnersRequirement.selector);

        new SharedWallet(_owners, _requiredApprovals);
    }

    function testSubmitTransaction() public {
        bytes memory data = abi.encodeWithSignature("receiveFunds()");

        vm.prank(owner1);
        uint256 transactionId = wallet.submitTransaction(recipient, 1 ether, data);

        (address to, uint256 value, bytes memory storedData, bool executed, uint256 approvalCount) =
            wallet.transactions(transactionId);
        assertEq(to, recipient);
        assertEq(value, 1 ether);
        assertEq(storedData, data);
        assertFalse(executed);
        assertEq(approvalCount, 0);
    }

    function testNonOwnerCannotSubmitOrApprove() public {
        vm.prank(address(0x99));
        vm.expectRevert(SharedWallet.NotOwner.selector);
        wallet.submitTransaction(recipient, 0, "");

        vm.prank(address(0x99));
        vm.expectRevert(SharedWallet.NotOwner.selector);
        wallet.approveTransaction(0);
    }

    function testCannotApproveTwiceAndCanRevoke() public {
        vm.prank(owner1);
        wallet.submitTransaction(recipient, 1 ether, "");

        vm.prank(owner1);
        wallet.approveTransaction(0);
        (,,,, uint256 approvalCount) = wallet.transactions(0);
        assertEq(approvalCount, 1);

        vm.prank(owner1);
        vm.expectRevert(SharedWallet.TransactionAlreadyApproved.selector);
        wallet.approveTransaction(0);

        vm.prank(owner1);
        wallet.revokeApproval(0);
        (,,,, approvalCount) = wallet.transactions(0);
        assertEq(approvalCount, 0);

        vm.prank(owner1);
        vm.expectRevert(SharedWallet.TransactionNotApproved.selector);
        wallet.revokeApproval(0);
    }

    function testExecutesAfterRequiredApprovals() public {
        vm.prank(owner1);
        wallet.submitTransaction(recipient, 1 ether, "");

        vm.prank(owner1);
        wallet.approveTransaction(0);
        vm.prank(owner2);
        wallet.approveTransaction(0);

        uint256 recipientBalanceBefore = recipient.balance;
        vm.prank(owner3);
        wallet.executeTransaction(0);

        assertEq(recipient.balance, recipientBalanceBefore + 1 ether);
        (,,, bool executed,) = wallet.transactions(0);
        assertTrue(executed);

        vm.prank(owner1);
        vm.expectRevert(SharedWallet.TransactionAlreadyExecuted.selector);
        wallet.executeTransaction(0);
    }

    function testCannotExecuteWithoutEnoughApprovals() public {
        vm.prank(owner1);
        wallet.submitTransaction(recipient, 1 ether, "");
        vm.prank(owner1);
        wallet.approveTransaction(0);

        vm.prank(owner1);
        vm.expectRevert(SharedWallet.NotEnoughApprovals.selector);
        wallet.executeTransaction(0);
    }

    function testExecutionFailureDoesNotConsumeTransaction() public {
        RevertingTarget target = new RevertingTarget();
        vm.prank(owner1);
        wallet.submitTransaction(address(target), 0, "");
        vm.prank(owner1);
        wallet.approveTransaction(0);
        vm.prank(owner2);
        wallet.approveTransaction(0);

        vm.prank(owner1);
        vm.expectRevert(SharedWallet.TransactionExecutionFailed.selector);
        wallet.executeTransaction(0);

        (,,, bool executedAfterFailure,) = wallet.transactions(0);
        assertFalse(executedAfterFailure);
    }
}
