// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./Character.sol";
import "./IParent.sol";
import "./IWifeToBe.sol";

interface IHusbandToBe is Character {

  function getProfile() external view returns (Profile memory);
  function getEligibility() external view returns(bool);
  function createJointAccount() external;
}