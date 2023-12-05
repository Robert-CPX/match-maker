// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface Character {
  event Proposal(address indexed who, address indexed engagedTo);
  error AgeTooLow();
  error AgeTooHigh();
  error SexualMismatch();

  enum Status { SINGLE, TAKEN, MARRIED, DIVORCED }
  enum Gender { MALE, FEMALE }
  enum Nature { DRUNK, NONDRUNK}

  struct Profile {
    uint age;
    Gender gender;
    Status status;
    uint ethnic;
    IERC20 bank;
    IERC721 assets;
    Nature nature;
  }

  struct Criteria {
    uint age;
    Gender gender;
    uint miniBankBalance;
    IREC20 bank;
    IERC721 assets;
    bool shouldOwnAProperty;
    uint ethnic;
    Status status;
    Nature nature;
  }

  function getProfile() external view returns(Profile memory);
  function getEligibility() external view returns(bool);
  
}