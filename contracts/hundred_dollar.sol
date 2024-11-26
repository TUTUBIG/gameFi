// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "hardhat/console.sol";

contract hundredDollarGame {
    address private constant donateReceiver = address(uint160(uint256(0x000)));
    uint status; // 0 valid, 1 invalid

    address private immutable holderAddress;
    uint256 private immutable bidStepAmount;
    uint256 private holdeAmount;

    address private winnerAddress;
    uint256 private winAmount;

    address private loserAddress;
    uint256 private loseAmount;

    struct refundable {
        address refundableAddress;
        uint256 refundableAmount;
    }

    refundable[] private refunders;

    event amountDeposit(address indexed depositor, uint256 depositAmount);
    event amountBid(address indexed bidder, uint256 bidAmount);
    event rewardClaim(address indexed owner,address indexed loser, uint256 winAmount, uint256 loseAmount);

    constructor(uint256 step) payable  {
        console.log("contract deployed by:", msg.sender);
        holderAddress = msg.sender;
        holdeAmount = msg.value;
        bidStepAmount = step;
        emit amountDeposit(holderAddress, holdeAmount);
    }

    function deposit() external payable {
        console.log(msg.sender, "deposit", msg.value);
        require(msg.sender == holderAddress, "only holder could deposit more ctyptos");
        holdeAmount += msg.value;
        emit amountDeposit(msg.sender, msg.value);
    }

    function bid() external payable {
        console.log(msg.sender, "bid", msg.value);
        require(msg.sender != holderAddress,"holder can't bid for themself");
        require(msg.value > winAmount,"bid amount should be the biggest number");
        require(msg.value % bidStepAmount == 0,"bid amount should be number which is times by the step bid amount");
        refunders.push(refundable({
            refundableAddress: loserAddress,
            refundableAmount: loseAmount
        }));
        loserAddress = winnerAddress;
        loseAmount = winAmount;
        winnerAddress = msg.sender;
        winAmount = msg.value;
        emit amountBid(msg.sender, msg.value);
    }

    function claimReward() external {
        console.log("claim reward");
        require(status == 0,"game is end");
        status = 1;
        
        uint256 winnerGet = holdeAmount;
        for (uint i = 0;i < refunders.length;i++) {
            if (refunders[i].refundableAddress == winnerAddress) {
                winnerGet += refunders[i].refundableAmount;
            }
        }

        uint256 holderGet = winAmount + loseAmount;

        uint256 donateAmount;
        if (winAmount > holderGet) {
            donateAmount = winAmount * 5 / 100;
            winAmount -= donateAmount;
        } else {
            donateAmount = holderGet * 5 / 100;
            holderGet -= donateAmount;
        }

        payable(donateReceiver).transfer(donateAmount);
        payable(holderAddress).transfer(holderGet);
        payable(winnerAddress).transfer(winnerGet);

        emit rewardClaim(winnerAddress,loserAddress,winAmount,loseAmount);
    }
}