// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

contract Lottery {
    address public manager;
    address payable[] public players;
    address payable public winner;

    constructor() {
        manager = msg.sender;
    }

    function enterLottery() external payable {
        require(msg.value == 1 ether, "You must send exactly 1 Ether to enter the lottery.");
        players.push(payable(msg.sender));
    }

    function getBalance() public view returns (uint) {
        require(msg.sender == manager, "Only the manager can check the balance.");
        return address(this).balance;
    }

    function random() public view returns (uint) {
        return uint(keccak256(abi.encodePacked(block.prevrandao, players.length, block.timestamp)));
    }

    function selectWinner() public {
        require(msg.sender == manager, "Only the manager can select the winner.");
        require(players.length >= 3, "At least 3 players are required to select a winner.");
        uint randomIndex = random() % players.length;
        winner = players[randomIndex];
        uint balance = address(this).balance;
        require(balance > 0, "The contract balance is zero.");
        winner.transfer(balance);
        players=new address payable[](0);
    }
}