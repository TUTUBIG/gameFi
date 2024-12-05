// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "remix_tests.sol";
import "../contracts/hundred_dollar.sol";

contract hundredDollarGameTest {
    
    HundredDollarGame gameTest;
    address payable public deployer = payable(address(0x123));

    /// #sender: account-0
    /// #value: 10
    function beforeAll () public payable  {
        gameTest = new HundredDollarGame{value: msg.value}(5,60,address(0));
    }

    function checkContractDeployInitState() public  {
        (, , , uint256 holdeAmount, uint256 endTime ) = gameTest.getGameInfo();
        Assert.equal(holdeAmount, 10, "hold amount is not expected");
        Assert.equal(endTime, block.timestamp + 60, "game endtime is not expected");
    }

    /// #sender: account-1
    /// #value: 1
    function checkWinner() public payable  {
        try gameTest.bid{value: msg.value} (0) {
            (, , uint256 winAmount, ,  ) = gameTest.getGameInfo();
            Assert.equal(winAmount,msg.value,"winamount is not expected");
        } catch Error(string memory reason) {
            Assert.ok(false,reason);
        }
    }

    function checkWinnerClaim() public {
        try gameTest.claimReward() {
            Assert.ok(true,"");
        } catch Error(string memory reason) {
            Assert.ok(false,reason);
        }
    }
}