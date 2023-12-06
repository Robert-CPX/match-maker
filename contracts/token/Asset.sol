// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Asset is ERC20 {
  constructor() ERC20("Asset", "AST") {
    _mint(msg.sender, 100_000_000 * decimals());
  }
}