// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IBank {
  event JoinAccountCreated(bytes32);
  event WithdrawalInitiated(uint, bytes32);
  
  error AlreadyAJoinPartner(address);
  error WithdrawalTimeUndermined(uint);
  error PartnerSignatureRequired();
  error InvalidWithdrawalAmount();

  struct Signature {
    address signer;
    uint count;
  }

  struct AccountData {
    address owner;
    uint balances;
    uint withdrawAmount;
    bool isPending;
  }

  struct PendingWithdraw {
    address initiator;
    uint amount;
    uint timestamp;
    bool inQueue;
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

  function getBalance() external view returns(uint256);
  function withdraw() external;
  function deposit(bytes32 accountId) external payable returns(bool);
  function initiateAccountClosure() external returns(bool);
  function createJointAccount(address partner) external payable returns(bytes32 accountId, bool success);
  function signJointAccountCreation(bytes32 accountId) external payable returns(bool);
  function initiateWithdrawal() external returns(bool);
  function signWithdrawalRequest(bytes32 accountId, uint amount) external returns(bool);
  function cancelWithdrawalRequest() external returns(bool);
}