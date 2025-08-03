// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

contract EventContract{
    struct Event{
        address organiser;
        uint date;
        uint price;
        uint ticketCount;
        uint ticketRemain;
        string name;
    }

    mapping (uint=>Event) public events;
    mapping (address=>mapping (uint=>uint)) public tickets;
    uint public nextId;

    function createEvent(string memory _name,uint date,uint _price,uint _ticketCount) external {
        require(date>block.timestamp,"You can not create event for the past events");
        require(_ticketCount>0,"Ticket count must be greater than zero");
        require(_price>0,"Price must be greater than zero");
        events[nextId]=Event(msg.sender,date,_price,_ticketCount,_ticketCount,_name);
        nextId++;
    }

    function buyTicket(uint id,uint amount) external payable  {
        require(events[id].date!=0,"Event does not exist");
        require(block.timestamp<events[id].date,"The events has been completed");
        require(events[id].ticketRemain>=amount,"There is not enough ticket");
        Event storage _event=events[id];
        require(msg.value==_event.price*amount,"The amount is not sufficient to but the ticlets");
        _event.ticketRemain=amount;
        tickets[msg.sender][id]=amount;
    }

    function transfer(uint id,uint amount,address _to) external {
        require(events[id].date!=0,"Event does not exist");
        require(block.timestamp<events[id].date,"The events has been completed");
        require(tickets[msg.sender][id]>=amount,"You do not have enough ticket");
        tickets[msg.sender][id]-=amount;
        tickets[_to][id]+=amount;  
    }
}