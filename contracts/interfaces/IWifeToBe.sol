// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./Character.sol";

interface IWifeToBe is Character {
  event Pregnancy(bytes32 pregnacy, address indexed _husband);
}