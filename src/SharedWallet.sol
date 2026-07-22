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
    error InvalidOwner();
    error OwnerAlreadyExists();
    error OwnerDoesNotExist();
    error CannotRemoveLastOwner();
    error RequirementExceedsOwnerCount();
    error NotOwner();
    error OnlyWallet();
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
    event OwnerAdded(address indexed owner);
    event OwnerRemoved(address indexed owner);
    event RequirementChanged(uint16 requiredApprovals);

    modifier onlyOwner() {
        if (!isOwner[msg.sender]) revert NotOwner();
        _;
    }

    modifier onlyWallet() {
        if (msg.sender != address(this)) revert OnlyWallet();
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

    // These administration functions must be called through an approved wallet transaction.
    function addOwner(address owner) external onlyWallet {
        if (owner == address(0)) revert InvalidOwner();
        if (isOwner[owner]) revert OwnerAlreadyExists();

        isOwner[owner] = true;
        owners.push(owner);
        emit OwnerAdded(owner);
    }

    function removeOwner(address owner) external onlyWallet {
        if (!isOwner[owner]) revert OwnerDoesNotExist();
        if (owners.length == 1) revert CannotRemoveLastOwner();
        if (requiredApprovals > owners.length - 1) revert RequirementExceedsOwnerCount();

        isOwner[owner] = false;
        for (uint256 i = 0; i < owners.length; i++) {
            if (owners[i] == owner) {
                owners[i] = owners[owners.length - 1];
                owners.pop();
                break;
            }
        }

        // A removed owner must no longer count toward pending transactions.
        for (uint256 i = 0; i < transactions.length; i++) {
            if (!transactions[i].executed && approved[i][owner]) {
                approved[i][owner] = false;
                transactions[i].approvalCount--;
            }
        }

        emit OwnerRemoved(owner);
    }

    function changeRequirement(uint16 newRequiredApprovals) external onlyWallet {
        if (newRequiredApprovals == 0) revert InvalidApprovalRequirement();
        if (newRequiredApprovals > owners.length) revert RequirementExceedsOwnerCount();

        requiredApprovals = newRequiredApprovals;
        emit RequirementChanged(newRequiredApprovals);
    }

    function getOwners() external view returns (address[] memory) {
        return owners;
    }

    function getTransactionCount() external view returns (uint256) {
        return transactions.length;
    }

    function getTransaction(uint256 transactionId)
        external
        view
        transactionExists(transactionId)
        returns (Transaction memory)
    {
        return transactions[transactionId];
    }

    function getConfirmations(uint256 transactionId)
        external
        view
        transactionExists(transactionId)
        returns (address[] memory confirmations)
    {
        uint256 confirmationCount;
        for (uint256 i = 0; i < owners.length; i++) {
            if (approved[transactionId][owners[i]]) confirmationCount++;
        }

        confirmations = new address[](confirmationCount);
        uint256 index;
        for (uint256 i = 0; i < owners.length; i++) {
            if (approved[transactionId][owners[i]]) confirmations[index++] = owners[i];
        }
    }
}
