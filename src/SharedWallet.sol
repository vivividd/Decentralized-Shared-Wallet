// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

contract SharedWallet {
    struct Transaction {
        address to;
        uint256 value;
        bytes data;
        bool executed;
        uint256 approvalCount;
    }

    address[] public owners;
    uint16 public requiredApprovals;
    mapping(address => bool) public isOwner;
    Transaction[] public transactions;
    mapping(uint256 => mapping(address => bool)) public approved;

    error InvalidOwnersRequirement();
    error InvalidApprovalRequirement();
    error NotOwner();
    error InvalidRecipient();
    error TransactionDoesNotExist();
    error TransactionAlreadyExecuted();
    error TransactionAlreadyApproved();
    error TransactionNotApproved();
    error NotEnoughApprovals();
    error TransactionExecutionFailed();

    event Deposit(address indexed sender, uint256 amount, uint256 balance);
    event TransactionSubmitted(uint256 indexed transactionId, address indexed to, uint256 value, bytes data);
    event TransactionApproved(uint256 indexed transactionId, address indexed owner);
    event TransactionApprovalRevoked(uint256 indexed transactionId, address indexed owner);
    event TransactionExecuted(uint256 indexed transactionId);

    modifier onlyOwner() {
        if (!isOwner[msg.sender]) revert NotOwner();
        _;
    }

    modifier transactionExists(uint256 transactionId) {
        if (transactionId >= transactions.length) revert TransactionDoesNotExist();
        _;
    }

    modifier notExecuted(uint256 transactionId) {
        if (transactions[transactionId].executed) revert TransactionAlreadyExecuted();
        _;
    }

    constructor(address[] memory _owners, uint16 _requiredApprovals) {
        if (_owners.length == 0) revert InvalidOwnersRequirement();

        if (_owners.length < _requiredApprovals || _requiredApprovals <= 0) revert InvalidApprovalRequirement();

        for (uint256 i = 0; i < _owners.length; i++) {
            address owner = _owners[i];

            if (owner == address(0)) revert InvalidOwnersRequirement();

            if (isOwner[owner]) revert InvalidOwnersRequirement();

            isOwner[owner] = true;
            owners.push(owner);
        }

        requiredApprovals = _requiredApprovals;
    }

    receive() external payable {
        emit Deposit(msg.sender, msg.value, address(this).balance);
    }

    function submitTransaction(address to, uint256 value, bytes calldata data)
        external
        onlyOwner
        returns (uint256 transactionId)
    {
        if (to == address(0)) revert InvalidRecipient();

        transactionId = transactions.length;
        transactions.push(Transaction({to: to, value: value, data: data, executed: false, approvalCount: 0}));
        emit TransactionSubmitted(transactionId, to, value, data);
    }

    function approveTransaction(uint256 transactionId)
        external
        onlyOwner
        transactionExists(transactionId)
        notExecuted(transactionId)
    {
        if (approved[transactionId][msg.sender]) revert TransactionAlreadyApproved();

        approved[transactionId][msg.sender] = true;
        transactions[transactionId].approvalCount++;
        emit TransactionApproved(transactionId, msg.sender);
    }

    function revokeApproval(uint256 transactionId)
        external
        onlyOwner
        transactionExists(transactionId)
        notExecuted(transactionId)
    {
        if (!approved[transactionId][msg.sender]) revert TransactionNotApproved();

        approved[transactionId][msg.sender] = false;
        transactions[transactionId].approvalCount--;
        emit TransactionApprovalRevoked(transactionId, msg.sender);
    }

    function executeTransaction(uint256 transactionId)
        external
        onlyOwner
        transactionExists(transactionId)
        notExecuted(transactionId)
    {
        Transaction storage transaction = transactions[transactionId];
        if (transaction.approvalCount < requiredApprovals) revert NotEnoughApprovals();

        transaction.executed = true;
        (bool success,) = transaction.to.call{value: transaction.value}(transaction.data);
        if (!success) revert TransactionExecutionFailed();

        emit TransactionExecuted(transactionId);
    }
}
