// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";

contract CunningFox is ERC20, ERC20Permit {
    constructor() ERC20("CunningFox", "FOX") ERC20Permit("CunningFox") {
        _mint(msg.sender, 1_000_000_000 * (10 ** uint256(decimals())));
    }
}
