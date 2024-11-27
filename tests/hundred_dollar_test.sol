// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "../contracts/hundred_dollar.sol";

contract hundredDollarGameTest {
    
    hundredDollarGame gameTest;
    address payable public deployer = payable(address(0x123));

    /// #sender: account-0
    /// #value: 10
    function beforeAll () public {
        gameTest = new hundredDollarGame(5,60);
    }

    function checkContractDeployInitState() public view  {
        console.log("checkContractDeployInitState");
        (address winnerAddress, uint256 winAmount, uint256 holdeAmount, uint256 gameEndTime) = gameTest.getGameInfo();
        console.log(winnerAddress,winAmount,holdeAmount,gameEndTime);
    }
}