// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;
import "hardhat/console.sol";
import "contracts/fangible_token.sol";


enum state { running, end }

contract HundredDollarGame {
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

    address private immutable tokenAddress;

    struct refundable {
        address refundableAddress;
        uint256 refundableAmount;
    }

    refundable[] private refunders;

    event amountDeposit(address indexed depositor,address indexed tokenAddress, uint256 depositAmount);
    event amountBid(address indexed bidder,address indexed tokenAddress, uint256 bidAmount);
    event rewardClaim(address indexed tokenAddress,address indexed winner,address indexed loser, uint256 winAmount, uint256 loseAmount);
    event refundClaim(address indexed claimer, uint256 refundAmount);

    constructor(uint256 step,uint256 gameLifeSeconds,address _tokenAddress) payable  {
        tokenAddress = _tokenAddress;
        holderAddress = msg.sender;
        if (tokenAddress == address(0)) {
            holdeAmount = msg.value;
        }
        bidStepAmount = step;
        gameLifePeriod = state.running;
        gameEndTime = block.timestamp + gameLifeSeconds;

        emit amountDeposit(holderAddress, tokenAddress,holdeAmount);
    }

    function deposit(uint256 tokenAmount) external payable {
        require(gameLifePeriod == state.running, "only deposit before game end");
        require(msg.sender == holderAddress, "only holder could deposit more ctyptos");
        uint256 depositAmount;
        if (tokenAddress != address(0)) {
            CunningFox token = CunningFox(tokenAddress);
            require(token.allowance(msg.sender, address(this)) >= tokenAmount, "Insufficient token allowance");
            require(token.balanceOf(msg.sender) >= tokenAmount, "Insufficient token balance");
            require(token.transferFrom(msg.sender, address(this), tokenAmount), "Token transfer failed");
            depositAmount = tokenAmount;
        } else {
            depositAmount = msg.value;            
        }
        holdeAmount += depositAmount;
        emit amountDeposit(msg.sender,tokenAddress, depositAmount);
    }

    function bid(uint256 tokenAmount) external payable {
        require(gameLifePeriod == state.running, "only bid before game end");
        // unit test can't pass this check
        require(msg.sender != holderAddress,"holder can't bid for themself");
        uint256 bidAmount;
        if (tokenAddress != address(0)) {
            IERC20 token = IERC20(tokenAddress);
            require(token.allowance(msg.sender, address(this)) >= tokenAmount, "Insufficient token allowance");
            require(token.balanceOf(msg.sender) >= tokenAmount, "Insufficient token balance");
            require(token.transferFrom(msg.sender, address(this), tokenAmount), "Token transfer failed");
            bidAmount = tokenAmount;
        } else {
            bidAmount = msg.value;
        }
        
        require(bidAmount > winAmount,"bid amount should be the biggest number");
        require(bidAmount % bidStepAmount == 0,"bid amount should be number which is times by the step bid amount");
        refunders.push(refundable({
            refundableAddress: loserAddress,
            refundableAmount: loseAmount
        }));
        loserAddress = winnerAddress;
        loseAmount = winAmount;
        winnerAddress = msg.sender;
        winAmount = bidAmount;

        emit amountBid(msg.sender,tokenAddress, bidAmount);
    }

    function claimReward() external {
        require(gameLifePeriod == state.running, "only claim before game end");

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

        // unit test can't pass
        if (tokenAddress != address(0)) {
            IERC20 token = IERC20(tokenAddress);
            token.transfer(donateReceiver, donateAmount);
            token.transfer(holderAddress, holderGet);
            token.transfer(winnerAddress, winnerGet);
        } else {
            payable(donateReceiver).transfer(donateAmount);
            payable(holderAddress).transfer(holderGet);
            payable(winnerAddress).transfer(winnerGet);
        }
        

        emit rewardClaim(tokenAddress,winnerAddress,loserAddress,winAmount,loseAmount);
    }

    function claimRefund() external {
        uint256 refundAmount;
        for (uint i = 0;i < refunders.length;i++) {
            if (refunders[i].refundableAddress == msg.sender) {
                refundAmount += refunders[i].refundableAmount;
                refunders[i].refundableAmount = 0;
            }
        }

        if (refundAmount == 0) {
            return;
        }

        if (tokenAddress != address(0)) {
            IERC20 token = IERC20(tokenAddress);
            token.transfer(msg.sender, refundAmount);
        } else {
            payable(msg.sender).transfer(refundAmount);
        }

        emit refundClaim(msg.sender, refundAmount);
    }

    function startGame(uint256 step,uint256 gameLifeSeconds,address _tokenAddress,uint256 tokenAmount) external payable  {
        require(gameLifePeriod == state.end,"need to end previous game first");
        // give 10 hours for refunder to claim after the game end
        require(block.timestamp > gameEndTime + 36000);

        // send all crypto tokens to holder
        uint256 remainRefundAmount;
        for (uint i = 0; i < refunders.length; i++) {
            remainRefundAmount += refunders[i].refundableAmount;
        }
        delete refunders;
        bidStepAmount = step;
        gameLifePeriod = state.running;
        gameEndTime = block.timestamp + gameLifeSeconds;

       

        if (remainRefundAmount > 0) {
             if (_tokenAddress != address(0)) {
                IERC20 token = IERC20(_tokenAddress);
                token.transfer(holderAddress, remainRefundAmount);
            } else {
                payable(holderAddress).transfer(remainRefundAmount);
            }
        }

        
        if (tokenAddress != address(0)) {
            holdeAmount = tokenAmount;
        } else {
            holdeAmount = msg.value;
        }

        emit amountDeposit(msg.sender, tokenAddress, holdeAmount);
    }

    function getGameInfo() external view returns (address,address ,uint256, uint256,uint256) {
        return (tokenAddress,winnerAddress,winAmount,holdeAmount,gameEndTime);
    }

    function getRefundAmount() external view returns (address,uint256) {
        uint256 refundAmount;
        for (uint i = 0; i < refunders.length; i++) {
            if (refunders[i].refundableAddress == msg.sender) {
                refundAmount += refunders[i].refundableAmount;
            }
        }
        return (tokenAddress,refundAmount);
    }
}