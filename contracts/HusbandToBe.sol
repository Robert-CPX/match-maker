// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./interfaces/IHusbandToBe.sol";
import "./interfaces/IBank.sol";

contract HusbandToBe is IHusbandToBe {
  IBank private jointBank;
  bool public isMarried;

  constructor() {
  }
  function getEligibility() external view returns(bool) {
    require(msg.sender == address(jointBank), "HusbandToBe: unauthorized");
    return isMarried;
  }
}