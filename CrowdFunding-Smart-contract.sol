// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract CrowdFunding{

    uint public target;
    uint public time;
    address public manager;
    uint public AmountCollected;
    uint public minimumAmt;
    mapping(address => uint) public contributors;
    uint public NoOfContributor;

    struct Request{
        string description;
        address payable recipient;
        uint value;
        bool completed;
        uint NoOfVotes;
        mapping( address => bool) voter;
    }

    mapping(uint => Request) public requests;
    uint public NoOfRequests;

    constructor(uint _target,uint _time){
        target = _target;
        time = block.timestamp+_time;
        minimumAmt = 100 wei;
        manager = msg.sender;
    }

    function sendETH() public payable {
        require(msg.value >= minimumAmt,"Minimum amount must be met");
        require(block.timestamp < time);
        if(contributors[msg.sender]==0){
            NoOfContributor++;
        }
        contributors[msg.sender]+=msg.value;
        AmountCollected+=msg.value;
    }

    function getContractBalance() public view returns(uint){
        return address(this).balance;
    }

    function refund() public {
        require(contributors[msg.sender] > 0,"You are not a contributor");
        require(block.timestamp > time,"DeadLine has not met");
        require(AmountCollected < target);
        address payable user = payable(msg.sender);
        user.transfer(contributors[msg.sender]);
        contributors[msg.sender] = 0;
    }

    modifier OnlyManager() {
    require(msg.sender == manager,"You are not the Manager");
    _;
    }

    function CreateRequest(string memory _description,address payable _recipient,uint _value) public OnlyManager{
       
        Request storage newRequest = requests[NoOfRequests];
        NoOfRequests++;
        newRequest.description = _description;
        newRequest.recipient = _recipient;
        newRequest.value = _value;
        newRequest.completed = false;
        newRequest.NoOfVotes = 0;
    }

    function voteRequest(uint _RequestNo) public {
        require(contributors[msg.sender] > 0,"You are not a contributor");
        Request storage newRequest = requests[_RequestNo];
        require(newRequest.voter[msg.sender]==false,"You have already voted");
        newRequest.voter[msg.sender]=true;
        newRequest.NoOfVotes++;

    }
    
    function makePayment(uint _RequestNo) public payable OnlyManager {
        require(AmountCollected >= target);
        Request storage newRequest = requests[_RequestNo];
        require(newRequest.completed == false,"This request has already been processed.");
        require(newRequest.NoOfVotes > NoOfContributor/2);
        newRequest.recipient.transfer(newRequest.value);
        newRequest.completed = true;
    }
}