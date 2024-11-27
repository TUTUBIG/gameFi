// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "hardhat/console.sol";

enum state { running, end }

contract hundredDollarGame {
    address private constant donateReceiver = address(uint160(uint256(0x000)));
    state private gameLifePeriod;

    address private immutable holderAddress;
    uint256 private bidStepAmount;
    uint256 private holdeAmount;
    uint256 private gameEndTime;

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
    event rewardClaim(address indexed winner,address indexed loser, uint256 winAmount, uint256 loseAmount);
    event refundClaim(address indexed claimer, uint256 refundAmount);

    constructor(uint256 step,uint256 gameLifeSeconds) payable  {
        console.log("contract deployed by:", msg.sender,"deposit amount",msg.value);
        holderAddress = msg.sender;
        holdeAmount = msg.value;
        bidStepAmount = step;
        gameLifePeriod = state.running;
        gameEndTime = block.timestamp + gameLifeSeconds;

        emit amountDeposit(holderAddress, holdeAmount);
    }

    function deposit() external payable {
        console.log(msg.sender, "deposit", msg.value);
        require(gameLifePeriod == state.running, "only deposit before game end");
        require(msg.sender == holderAddress, "only holder could deposit more ctyptos");
        holdeAmount += msg.value;

        emit amountDeposit(msg.sender, msg.value);
    }

    function bid() external payable {
        console.log(msg.sender, "bid", msg.value);
        require(gameLifePeriod == state.running, "only bid before game end");
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
        console.log(msg.sender, "claim reward");
        require(gameLifePeriod == state.running, "only claim before game end");
        // check end time
        require(block.timestamp > gameEndTime,"only claim after game end time");

        gameLifePeriod = state.end;
        gameEndTime = block.timestamp;
        
        uint256 winnerGet = holdeAmount;
        for (uint i = 0;i < refunders.length;i++) {
            if (refunders[i].refundableAddress == winnerAddress) {
                winnerGet += refunders[i].refundableAmount;
                refunders[i].refundableAmount = 0;
            }
        }

        uint256 holderGet = winAmount + loseAmount;

        uint256 donateAmount;
        if (winAmount > holderGet) {
            donateAmount = (winAmount-holderGet) * 5 / 100;
            winAmount -= donateAmount;
        } else {
            donateAmount = (holderGet - winAmount) * 5 / 100;
            holderGet -= donateAmount;
        }

        holdeAmount = 0;
        winAmount = 0;
        loseAmount = 0;

        payable(donateReceiver).transfer(donateAmount);
        payable(holderAddress).transfer(holderGet);
        payable(winnerAddress).transfer(winnerGet);

        emit rewardClaim(winnerAddress,loserAddress,winAmount,loseAmount);
    }

    function claimRefund() external {
        console.log(msg.sender, "claim refund");
        uint256 refundAmount;
        for (uint i = 0;i < refunders.length;i++) {
            if (refunders[i].refundableAddress == msg.sender) {
                refundAmount += refunders[i].refundableAmount;
                refunders[i].refundableAmount = 0;
            }
        }

        payable(msg.sender).transfer(refundAmount);

        emit refundClaim(msg.sender, refundAmount);
    }

    function startGame(uint256 step,uint256 gameLifeSeconds) external payable  {
        console.log("game started by:", msg.sender);
        require(gameLifePeriod == state.end,"need to end previous game first");
        // give 10 hours for refunder to claim after the game end
        require(block.timestamp > gameEndTime + 36000);

        // send all crypto tokens to holder
        uint256 remainRefundAmount;
        for (uint i = 0; i < refunders.length; i++) {
            remainRefundAmount += refunders[i].refundableAmount;
        }
        delete refunders;
        holdeAmount = msg.value;
        bidStepAmount = step;
        gameLifePeriod = state.running;
        gameEndTime = block.timestamp + gameLifeSeconds;

        emit amountDeposit(holderAddress, holdeAmount);

        if (remainRefundAmount == 0) {
            return;
        }

        payable(holderAddress).transfer(remainRefundAmount);
    }

    function getGameInfo() external view returns (address ,uint256, uint256,uint256) {
        return (winnerAddress,winAmount,holdeAmount,gameEndTime);
    }

    function getRefundAmount() external view returns (uint256) {
        uint256 refundAmount;
        for (uint i = 0; i < refunders.length; i++) {
            if (refunders[i].refundableAddress == msg.sender) {
                refundAmount += refunders[i].refundableAmount;
            }
        }
        return refundAmount;
    }
}