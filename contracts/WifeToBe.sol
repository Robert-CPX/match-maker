// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./interfaces/IHusbandToBe.sol";
import "./interfaces/IWifeToBe.sol";
import "./interfaces/IBank.sol";

contract WifeToBe is IWfeToBe {
  IBank private jointBank;
  IHusbandToBe public husband;

  constructor() {

  }

  function getEligibility() external view returns(bool) {
    require(msg.sender == address(jointBank), "WifeToBe: unauthorized");
    return address(husband) == address(0);
  }
}