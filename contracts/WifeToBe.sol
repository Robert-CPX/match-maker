// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./interfaces/IHusbandToBe.sol";
import "./interfaces/IWifeToBe.sol";
import "./interfaces/IBank.sol";
import "./interfaces/IParent.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract WifeToBe is IWfeToBe, Ownable, Pausable, Context {
  IBank private jointBank;
  IHusbandToBe public husband;
  IParent public parent;
  bool private isReady;
  bytes32 private accountId;
  bytes32 private acceptance;
  Criteria public criteria;
  Status public status;

  modifier validateStatus(Status _status, string memory errorMessage) {
    require(status == _status, errorMessage);
    _;
    if (uint8(_status) < uint8(Status.MARRIED)) {
      status = Status(uint8(_status) + 1);
    }
  }

  modifier validateCaller(address expected, string memory errorMessage) {
    require(_msgSender() == expected, errorMessage);
    _;
  }

  constructor(
    IParent _parent,
    uint8 _age,
    bool _isMale,
    bool _shouldOwnAtLeastAProperty,
    IBank _bank,
    IERC20 asset,
    IERC721 _property,
    uint8 _nature,
    uint8 _ethnic,
    uint8 _status,
    uint _minimBankBalance,
  ) {
    if (address(_parent) == address(0)) {
      revert InvalidParentAddress();
    }
    if (address(parent) != address(0)) {
      require(_parent == parent, "WifeToBe: parent address cannot be changed");
    }
    require(
      _status < 3 &&
      _nature < 2,
      "WifeToBe: status/nature out of bound"
    )
    jointBank = _bank;
    criteria = Criteria({
      age: _age,
      gender: Gender(_isMale ? 0 : 1),
      miniBankBalance: _minimBankBalance,
      asset: asset,
      property: _property,
      ethnic: _ethnic,
      status: Status(_status),
      nature: Nature(_nature),
    })
  }

  receive() external payable {
    require(msg.value > 0);
  }

  function setParent(IParent _parent) external returns (bool _success) {
    if (address(_parent) == address(0)) {
      revert InvalidParentAddress();
    }
    if (address(parent) != address(0)) {
      require(_parent == parent, "WifeToBe: parent address cannot be changed");
    }
    parent = _parent;
    return true;
  }

  function getPropose() external whenNotPausable validateStatus(Status.SINGLE, "Taken") returns(bool _proposalAccepted) {
    _proposalAccepted = true;
    Profile memory _p = IHusbandToBe(_msgSender()).getProfile();
    if (_p.age < criteria.age) {
      revert AgeTooLow();
    }
    if (_p.gender == Gender.FEMALE) {
      revert SexualMismatch();
    }
    if (IERC20(_p.asset).balanceof(_msgSender()) < criteria.miniBankBalance) {
      revert PleaseWorkHarder();
    }
    if (criteria.shouldOwnAProperty) {
      if (IERC721(_p.property).balanceof(_msgSender()) < 1) {
        revert YouShouldOwnAtLeastOneProperty();
      }
    }

    require(
      _p.nature == criteria.nature &&
      _p.status == criteria.status &&
      _p.ethnic == criteria.ethnic,
      "WifeToBe: you are not eligible to propose"
    );

    emit Proposal(_msgSender(), address(this));
    return _proposalAccepted;
  }

  function setMarriageStatus(IHusband _husband) 
    external
    whenNotPausable
    validateCaller(address(parent), "only parent can confirm status")
    validateStatus(Status.TAKEN, "WifeToBe: Taken")
    returns (bool) {
    require(
      address(_husband) != address(0),
      "WifeToBe: husband address cannot be empty"
    )
    husband = _husband;
    emit Married(address(_husband), address(this));
    return true;
  }

  function checkStatus() external view returns (string memory) {
    if (status == Status.SINGLE) {
      return "Single";
    }
    if (status == Status.TAKEN) {
      return "Taken";
    }
    if (status == Status.DIVORCED) {
      return "Divorced";
    }
    if (status == Status.MARRIED) {
      return "Married";
    }
  }

  function getBalance(address who) external view returns (uint256) {
    return address(who).balance;
  }

  function meetYourWife() 
    external 
    whenNotPausable
    validateCaller(address(husband), "WifeToBe: Taarr!")
    validateStatus(Status.MARRIED, "WifeToBe: Married")
    returns (bool) {
    acceptance = bytes32(abi.encodePacked(address(this), _msgSender()));
    emit Pregnancy(acceptance, _msgSender());
    return true;
  }

  function createJointAccount() public onlyOwner {
    if (address(husband) == address(0)) {
      revert NoMarriedYet();
    }
    (bytes32 _accountId, bool _success) = IBank(jointBank).createJointAccount(address(husband));
    request(_success, "failed")
    accountId = _accountId;
  }

  function checkBalance() public view onlyOwner returns (uint) {
    return IBank(jointBank).getBalance();
  }

  function signJointAccountCreation() public onlyOwner {
    bytes32 _accountId = accountId;
    require(
      IBank(jointBank).signJointAccountCreation(_accountId),
      "WifeToBe: failed to sign"
    )
  }

  function signWithdrawalRequest(uint amount) public onlyOwner {
    bytes32 _accountId = accountId;
    require(
      IBank(jointBank).signWithdrawalRequest(_accountId, amount),
      "WifeToBe: failed to sign"
    )
  }

  function deposit() public payable onlyOwner {
    bytes32 _accountId = accountId;
    require(
      IBank(jointBank).deposit(_accountId),
      "WifeToBe: failed to deposit"
    )
  }

  function initiateWithdrawal() public onlyOwner {
    require(IBank(jointBank).initiateWithdrawal(), "WifeToBe: Failed");
  }

  function cancelWithdrawalRequest() public onlyOwner {
    require(IBank(jointBank).cancelWithdrawalRequest(), "WifeToBe: Failed");
  }

  function withdraw() public onlyOwner {
    IBank(jointBank).withdraw();
  }

  function getEligibility() external view returns(bool) {
    require(msg.sender == address(jointBank), "WifeToBe: unauthorized");
    return address(husband) == address(0);
  }

  function paused() external view returns(bool) {
    return _paused();
  }

  function Unpaused() external view returns(bool) {
    return !_paused();
  }
}