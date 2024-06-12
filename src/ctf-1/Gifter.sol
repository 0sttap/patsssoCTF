// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/*
    This contract was created by an altruist who could no longer look at this world calmly,
    so he decided to create an action for people in need of help.
    For those who deposit a certain amount on the contract,
    he chooses a couple of addresses to whom he will double his deposit.
    But we all know what the harsh world does to all of us,
    so some who were lucky enough to double their deposit decided to rob an altruist for the same amount.
    Can you do the same?
*/

contract Gifter is Ownable {
    mapping(bytes32 => bool) public executed;
    mapping(address => uint256) public deposited;
    address[] public users;

    constructor() Ownable(msg.sender) {}

    function deposit() external payable {
        deposited[msg.sender] = msg.value;  
        users.push(msg.sender);     
    }

    function sendGift(
        address to,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        require(to != owner(), "All for people");
        require(deposited[to] != 0, "Not deposited");

        bytes32 msgHash = keccak256(abi.encode(to));
        address signer = ecrecover(msgHash, v, r, s);
        require(signer == owner(), "Invalid signer");

        bytes32 sigHash = keccak256(abi.encode(msgHash, v, r, s));
        require(!executed[sigHash], "Already executed");
        executed[sigHash] = true;

        uint256 amount = deposited[to] * 2;

        payable(to).transfer(amount);
    }
}
