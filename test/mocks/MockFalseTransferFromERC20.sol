// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockFalseTransferFromERC20 is ERC20 {
    uint256 public constant MINT_AMOUNT = 1e18;

    constructor() ERC20("Mock Token", "MT") {}

    function mint() external {
        _mint(msg.sender, MINT_AMOUNT);
    }

    function mint(uint256 amount) external {
        _mint(msg.sender, amount);
    }

    function transferFrom(address from, address to, uint256 value) public override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, value);
        _transfer(from, to, value);
        return false;
    }
}
