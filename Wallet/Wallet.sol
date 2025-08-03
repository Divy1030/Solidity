// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.2 <0.9.0;

contract MultiSig {
    address[] public owners;
    uint public numConfirmationsRequired;

    struct Transaction {
        address to;
        uint value;
        bool executed;
    }

    Transaction[] public transactions;

    // Mapping from tx ID => owner => confirmed
    mapping(uint => mapping(address => bool)) public isConfirmed;

    event TransactionSubmitted(
        uint transactionId,
        address indexed sender,
        address indexed receiver,
        uint amount
    );

    event TransactionConfirmed(uint transactionId);
    event TransactionExecuted(uint transactionId);

    constructor(address[] memory _owners, uint _numConfirmationsRequired) {
        require(_owners.length > 1, "Owners required must be greater than 1");
        require(
            _numConfirmationsRequired > 0 && _numConfirmationsRequired <= _owners.length,
            "Invalid number of required confirmations"
        );

        for (uint i = 0; i < _owners.length; i++) {
            require(_owners[i] != address(0), "Invalid owner");
            owners.push(_owners[i]);
        }

        numConfirmationsRequired = _numConfirmationsRequired;
    }

    function submitTransaction(address _to) public payable {
        require(_to != address(0), "Invalid receiver address");
        require(msg.value > 0, "Transfer amount must be greater than 0");

        uint transactionId = transactions.length;
        transactions.push(Transaction({
            to: _to,
            value: msg.value,
            executed: false
        }));

        emit TransactionSubmitted(transactionId, msg.sender, _to, msg.value);
    }

    function confirmTransaction(uint _transactionId) public {
        require(_transactionId < transactions.length, "Invalid transaction ID");
        require(!isConfirmed[_transactionId][msg.sender], "Already confirmed by this owner");

        isConfirmed[_transactionId][msg.sender] = true;
        emit TransactionConfirmed(_transactionId);

        if (isTransactionConfirmed(_transactionId)) {
            executeTransaction(_transactionId);
        }
    }

    function executeTransaction(uint _transactionId) public {
        require(_transactionId < transactions.length, "Invalid transaction ID");
        require(!transactions[_transactionId].executed, "Transaction already executed");

        Transaction storage txn = transactions[_transactionId];

        (bool success, ) = txn.to.call{value: txn.value}("");
        require(success, "Transaction execution failed");

        txn.executed = true;
        emit TransactionExecuted(_transactionId);
    }

    function isTransactionConfirmed(uint _transactionId) internal view returns (bool) {
        require(_transactionId < transactions.length, "Invalid transaction ID");

        uint confirmationCount = 0;
        for (uint i = 0; i < owners.length; i++) {
            if (isConfirmed[_transactionId][owners[i]]) {
                confirmationCount++;
            }
        }

        return confirmationCount >= numConfirmationsRequired;
    }
}
