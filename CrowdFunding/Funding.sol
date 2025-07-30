// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

contract Funding {
    mapping(address => uint) public contributors;
    address public manager;
    uint public target;
    uint public minimumAmount;
    uint public raisedAmount;
    uint public deadline;
    uint public numberOfContributors;
    uint public NumberofRequest;

    struct Request {
        string description;
        uint value;
        bool completed;
        address payable recipient;
        uint noofVoters;
        mapping(address => bool) voters;
    }

    mapping(uint => Request) public requests;

    constructor(uint _target, uint _deadline) {
        manager = msg.sender;
        target = _target;
        deadline = block.timestamp + _deadline;
        minimumAmount = 100 wei;
    }

    function sendEth() public payable {
        require(block.timestamp < deadline, "Contract deadline has expired");
        require(msg.value >= minimumAmount, "Amount should be greater than the minimum amount");

        if (contributors[msg.sender] == 0) {
            numberOfContributors++;
        }

        contributors[msg.sender] += msg.value;
        raisedAmount += msg.value;
    }

    function getBalance() public view returns (uint) {
        return address(this).balance;
    }

    function refund() public {
        require(block.timestamp > deadline && raisedAmount < target, "You are not eligible for a refund");
        require(contributors[msg.sender] > 0, "You are not eligible for a refund");

        address payable user = payable(msg.sender);
        user.transfer(contributors[msg.sender]);
        contributors[msg.sender] = 0;
    }

    modifier onlyManager() {
        require(msg.sender == manager, "You are not allowed");
        _;
    }

    function createRequest(string memory _description, uint _value, address payable _recipient) public onlyManager {
        NumberofRequest++;
        Request storage newRequest = requests[NumberofRequest];
        newRequest.description = _description;
        newRequest.value = _value;
        newRequest.completed = false;
        newRequest.recipient = _recipient;
        newRequest.noofVoters = 0;
    }

    function VotingRequest(uint _requestNo) public {
        require(contributors[msg.sender]>0,"You are not eligible to vote");
        Request storage newVoting= requests[_requestNo];
        require(newVoting.voters[msg.sender]==false,"You have already voted");
        newVoting.noofVoters++;
        newVoting.voters[msg.sender]=true;
    }

    function makepayment(uint _requestNo) public onlyManager {
        require(raisedAmount>target,"Target do not meet");
        Request storage newPayment= requests[_requestNo];
        require(newPayment.noofVoters>numberOfContributors/2,"Majority didn't meet");
        newPayment.recipient.transfer(newPayment.value);
        newPayment.completed=true;
    }
}