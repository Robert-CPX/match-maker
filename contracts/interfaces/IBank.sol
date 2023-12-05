// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IBank {

  struct Signature {
    address signer;
    uint count;
  }
  struct JointAccountData {
    address partnerA;
    address partnerB;
    Signature accountWithdrawalSignature;
    uint accountCloseSignature;
    uint balances;
    uint withdrawAmount;
    bool isPending;
  }

  function deposit(bytes32 accountId) external payable returns(bool);
  function withdraw(uint256 amount) external;
  function balanceOf(address account) external view returns (uint256);
  function getBalance() external view returns(uint256);
  function createJoinAccount(address partner) external payable returns(bytes32 accountId, bool success);
}