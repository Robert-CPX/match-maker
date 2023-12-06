// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./Character.sol";
import "./IHusbandToBe.sol";
import "./IWifeToBe.sol";

interface IParent is Character {
  
  struct Daughter {
    bool pricePaymentApproved;
    bool isOurDaugther;
    uint bridePrice;
    IHusbandToBe marriedTo;
  }

  function getMarriageApproval(IWifeToBe _daughter) external returns(bool);
  function getBridePrice() external view returns(uint);
}