// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./Character.sol";
import "./IHusbandToBe.sol";
import "./IParent.sol";

interface IWifeToBe is Character {
  event Pregnancy(bytes32 pregnacy, address indexed _husband);
  event Married(address indexed _husband, address indexed _wife);
  event Proposal(address indexed who, address indexed engagedTo);

  error InvalidParentAddress();
  error AgeToLow();
  error PleaseWorkHarder();
  error YouShouldOwnAtLeastOneProperty();

  function checkStatus() external view returns(string memory);
  function meetYourWife() external returns(bool);
  function setParent(IParent _parent) external returns(bool);
  function getPropose() external returns(bool);
  function setMarriageStatus(IHusband _husband) external returns(bool);
}