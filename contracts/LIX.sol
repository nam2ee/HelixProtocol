// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@klaytn/contracts/token/ERC20/ERC20.sol";

// BAYToken is a standard ERC20 token with an initial supply
contract LIXToken is ERC20 {
    address public owner_of_LIX;
    constructor(uint256 initialSupply) ERC20("HELIX", "LIX") {
        _mint(msg.sender, initialSupply);
        owner_of_LIX = msg.sender;
    }

    function mint(address _to, uint256 _amount) public {
        require(msg.sender == owner_of_LIX, "Only owner can call this function.");
        _mint(_to, _amount);
    }

}