// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;
import "remix_tests.sol";
import "../contracts/fangible_token.sol";
import "remix_accounts.sol";


contract MyTokenTest is CunningFox {

    function testTokenInitialValues() public {
        Assert.equal(name(), "CunningFox", "token name did not match");
        Assert.equal(symbol(), "FOX", "token symbol did not match");
        Assert.equal(decimals(), 18, "token decimals did not match");
        Assert.equal(totalSupply(), 1_000_000_000 ether, "token supply should be 1 billion ethers");
    }

    function testTokenMint() public  {
        uint256 balanceBefore = balanceOf(TestsAccounts.getAccount(1));
        transfer(TestsAccounts.getAccount(1), 1 ether);
        uint256 balanceAfter = balanceOf(TestsAccounts.getAccount(1));
        Assert.equal(balanceBefore, 0,"balance before mint should be zero");
        Assert.equal(balanceAfter, 1 ether,"balance after mint should be 1 ether");
    }
}