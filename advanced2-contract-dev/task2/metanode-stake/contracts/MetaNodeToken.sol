// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MetaNodeToken is ERC20 {
    constructor(uint256 totalSupply_) ERC20("MetaNode", "MN") {
        _mint(msg.sender, totalSupply_);
    }
}
