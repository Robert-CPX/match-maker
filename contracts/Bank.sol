// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./interfaces/Character.sol";
import "./interfaces/IBank.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Bank is IBank, ReentrancyGuard, Pausable, Ownable {
  // rate limit for withdraw
  uint withdrawWaitingPeriod;

  // mapping of account id to pending withdraw
  mapping (bytes32 => PendingWithdraw) public withdrawRequests;

  // completely signed and created accounts
  mapping (bytes32 => JointAccountData) private jointAccountLedger;

  // joint account holder records
  mapping (bytes32 => bool) private isJointAccountHolder;

  // mapping of user to joint account id
  mapping (address => bytes32) private userToAccountId;

  modifier isJointAccountHolder() {
    require(userToAccountId[msg.sender] != bytes32(0), "Bank: caller is not a joint account holder");
    _;
  }
  modifier isNotJointAccountHolder() {
    require(userToAccountId[msg.sender] == bytes32(0), "Bank: caller is not a joint account holder");
    _;
  }

  modifier isContractAddress() {
    require(
      Address.isContract(msg.sender),
      "Bank: caller is not a contract"
      );
    _;
  }

  modifier isPartnerAorB {
    bytes32 accountId = userToAccountId[msg.sender];
    JointAccountData memory jointAccountData = jointAccountLedger[accountId];
    require(
      jointAccountData.partnerA == msg.sender || jointAccountData.partnerB == msg.sender,
      "Bank: caller is not partner A or B")
      ;
    _;
  }

  constructor(uint _withdrawWaitingPeriod) {
    withdrawWaitingPeriod = _withdrawWaitingPeriod * 1 min;
  }

  // at least one of the joint account holders must have signed the withdrawal request
  function initiateWithdrawal external isJointAccountHolder isPartnerAorB isContractAddress returns (bool) {
    bytes32 accountId = userToAccountId[msg.sender];
    uint bankBalance = address(this).balance;
    JointAccountData memory jointAccountData = jointAccountLedger[accountId];
    PendingWithdraw memory pWithdraw = withdrawRequests[accountId];
    // check
    if (jointAccountData.accountWithdrawalSignature.signer == msg.sender) {
      revert PartnerSignatureRequired();
    }
    if (pWithdraw.amount == 0) {
      revert InvalidWithdrawalAmount();
    }
    require(
      !jointAccountData.isPending &&
      jointAccountData.accountWithdrawalSignature.count == 1 &&
      jointAccountData.balances >= pWithdraw.amount,
      "Bank: something not right"
    )
    // effect
    jointAccountLedger[accountId].balances -= pWithdraw.amount;
    jointAccountLedger[accountId].accountWithdrawalSignature.count = 0; // clear the signature immediately
    jointAccountLedger[accountId].timestamp = block.timestamp + withdrawWaitingPeriod;
    jointAccountLedger[accountId].inqQueue = true;
    // interaction
    emit WithdrawalInitiated(pWithdraw.amount, accountId);
    return true;
  }

  // any of the partners can deposit into their joint account
  function deposit(bytes32 accountId) external payable isJointAccountHolder isPartnerAorB returns (bool) {
    jointAccountLedger[accountId].balances += msg.value;
    return true;
  }

  function withdraw() external isContractAddress nonReentrant isJointAccountHolder {
    bytes32 accountId = userToAccountId[msg.sender];
    PendingWithdraw memory pWithdraw = withdrawRequests[accountId];
    // check
    require(
      pWithdraw.inQueue,
      "Bank: withdraw not initiated"
    );
    uint currentTime = block.timestamp;
    if (currentTime < pWithdraw.timestamp) {
      revert WithdrawalTimeUndermined(currentTime);
    }

    //effect
    delete withdrawRequests[accountId];

    //interaction
    (bool done, ) = msg.sender.call{value: pWithdraw.amount}("");
    require(done, "Bank: withdraw failed");
  }

  // either of the joint operator can cancel pending request.
  function cancelWithdrawalRequest() external isJointAccountHolder isPartnerAorB isContractAddress returns (bool) {
    bytes32 accountId = userToAccountId[msg.sender];
    require(
      !withdrawRequests[accountId].inQueue,
      "Bank: withdraw cannot be cancelled at this time"
    );
    delete withdrawRequests[accountId];
    return true;
  }

  function getBalance() external view isJointAccountHolder returns (uint256) {
    bytes32 accountId = userToAccountId[msg.sender];
    return jointAccountLedger[accountId].balances;
  }

  // implement circuit breaker by using pause, create joint account by partner A
  function createJointAccount(address partner) external payable isContractAddress whenNotPaused returns (bytes32 accountId, bool isPending) {
    require(
      Address.isContract(partner),
      "Bank: partner is not a contract"
    )
    require(
      Character(msg.sender).getEligibility() &&
      Character(partner).getEligibility(),
      "Bank: ineligible"
    );
    if (isJointAccountHolder[partner]) {
      revert AlreadyAJoinPartner(partner);
    }
    if (isJointAccountHolder[msg.sender]) {
      revert AlreadyAJoinPartner(msg.sender);
    }
    accountId = _createJointId(msg.sender, partner);
    userToAccountId[msg.sender] = accountId;
    isPending = true;
    jointAccountLedger[accountId] = JointAccountData({
      partnerA: msg.sender,
      partnerB: partner,
      accountWithdrawalSignature: Signature({
        signer: msg.sender, // msg.sender auto signs account creation, account will only be opened if partnerB signs
        count: 1
      }),
      accountCloseSignature: 0,
      balances: msg.value,
      withdrawAmount: 0,
      isPending: true
    });
    emit JoinAccountCreated(accountId);
    return (accountId, isPending);
  }

  function _createJointId(address a, address b) internal pure returns (bytes32) {
    return keccak256(abi.encode(a, b));
  }
  // sign joint account creation by partner A
  function signJointAccountCreation(bytes32 accountId) external payable isContractAddress isNotJointAccountHolder returns (bool) {

    require(jointAccountLedger[accountId].partnerB == msg.sender, "Bank: caller is not partner B");
    require(jointAccountLedger[accountId].isPending, "Bank: invalid account");

    jointAccountLedger[accountId].isPending = false;
    jointAccountLedger[accountId].balances += msg.value;
    isJointAccountHolder[msg.sender] = true;
    userToAccountId[msg.sender] = accountId;

    return true;
  }

  //either of the partner signs withdrawal request
  function signWithdrawalRequest(bytes32 accountId, uint amount) external isJointAccountHolder isContractAddress returns(bool) {
    JointAccountData memory jdata = jointAccountLedger[accountId];
    require(
      jdata.accountWithdrawalSignature.count == 0,
      "Bank: Already signed";
    )
    require(
      msg.sender == jdata.partnerA || msg.sender == jdata.partnerB,
      "Bank: invalid caller"
    )

    jointAccountLedger[accountId].accountWithdrawalSignature = Signature({
      signer: msg.sender,
      count: jdata.accountWithdrawalSignature.count + 1
    });

    withdrawRequests[accountId] = PendingWithdraw({
      initiator: msg.sender,
      amount: amount,
      timestamp: 0,
      inQueue: false
    });

    return true;
  }
  // either of the partner can initiate account closure, while the other partner can execute later.
  function initiateAccountClosure() external isJointAccountHolder isContractAddress returns(bool) {
    bytes32 accountId = userToAccountId[msg.sender];
    JointAccountData memory jdata = jointAccountLedger[accountId];
    require(
      jdata.accountCloseSignature == 0,
      "Already signed";
    )
    jointAccountLedger[accountId].accountCloseSignature ++;

    return true;
  }

  // close joint account, it's not a good practice
  function closeAccount() external returns(bool) {
    bytes32 accountId = userToAccountId[msg.sender];
    JointAccountData memory jdata = jointAccountLedger[accountId];
    require(
      jdata.accountCloseSignature == 1,
      "Bank: invalid account"
    )
    if (jdata.balances > 0) {
      uint8 multiplier = 50;
      uint share;
      unchecked {
        share = (jdata.balances * multiplier) / 100;
      }
      (bool done_1, ) = jdata.partnerA.call{value: share}("");
      (bool done_2, ) = jdata.partnerB.call{value: share}("");
      require(done_1 && done_2, "Bank: Account closure failed");
    }
    return true;
  }

  function pause() public onlyOwner {
    _pause();
  }

  function unpause() public onlyOwner {
    _unpause();
  }
}