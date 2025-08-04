// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

contract Drive{
    struct Access{
        address user;
        bool access;
    }
    mapping (address=>string[]) value;
    mapping (address=>mapping (address=>bool)) ownership; // address=>address=>bool)
    mapping (address=>Access[]) accessList;
    mapping (address=>mapping (address=>bool)) previousdata;

    function add(address _user,string memory url) external {
        value[_user].push(url);
    }

    function allow(address user) external {
        ownership[msg.sender][user]=true;
        if(previousdata[msg.sender][user]){
            for(uint i=0;i<accessList[msg.sender].length;i++){
                if(accessList[msg.sender][i].user==user){
                    accessList[msg.sender][i].access=true;
                }
            }
        }
        else{
            accessList[msg.sender].push(Access(user,true));
            previousdata[msg.sender][user]=true;
        }
    }

    function disallow(address user) external {
        ownership[msg.sender][user]=false;
        for(uint i=0;i<accessList[msg.sender].length;i++){
            if(accessList[msg.sender][i].user==user){
                accessList[msg.sender][i].access=false;
            }
        }
    }

    function display(address user) external view returns (string[] memory){
        require(ownership[user][msg.sender],"You are not allowed to access the data");
        return value[user];
    }

    function shareAccess() public view returns(Access[] memory){
        return accessList[msg.sender];
    }

}