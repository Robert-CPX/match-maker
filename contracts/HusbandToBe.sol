// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./interfaces/IHusbandToBe.sol";
import "./interfaces/IBank.sol";
import "./interfaces/IWifeToBe.sol";
import "./interfaces/IParent.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";

contract HusbandToBe is IHusbandToBe, Ownable, Pausable {
  IParent public parentInLaw;
  IWifeToBe public wifeToBe;
  IBank private jointBank;
  bool public isMarried;

  bytes32 private accountId;
  Profile public profile;

  constructor(
    uint age,
    IERC20 asset,
    IERC721 property,
    IBank _jointBank;
    uint8 _nature,
    uint8 _ethnic,
    uint8 _status,
    ) {
      if (address(asset) == address(0)) revert InvalidBankAddress();
      require(
        _nature < 2 &&
        _status < 3,
        "HusbandToBe: invalid nature/status"
      );
      jointBank = _jointBank;
      profile = Profile({
        age: age,
        gender: Gender.MALE,
        status: Status(_status),
        ethnic: _ethnic,
        asset: asset,
        property: property,
        nature: Nature(_nature)
      });
  }

  receive() external payable {
    require(msg.value > 0, "HusbandToBe: invalid amount");
  }

  function tryPropose() public onlyOwner {
    require(IWifeToBe(wifeToBe).getPropose(), "HusbandToBe: failed to propose");
  }

  function meetYourWife() public onlyOwner {
    require(IWifeToBe(wifeToBe).meetHusband(), "HusbandToBe: failed to meet");
  }

  function spendMoney(address to, uint amount) public onlyOwner {
    require(
      IERC20(_getAsset()).transfer(to, amount),
      "HusbandToBe: failed to transfer"
    );
  }

  function getProfile() external view returns (Profile memory) {
    return profile;
  }

  function payBridePrice(IWifeToBe _wifeToBe, IParent _inlaw) public onlyOwner {
    address inlaw_ = address(_inlaw);
    require(
    address(_wifeToBe) != address(0) &&
    address(_inlaw) != address(0),
    "HusbandToBe: invalid wife"
    );
    require(IERC20(_getAsset()).approve(inlaw_, _getBridePrice()), "HusbandToBe: failed to approve");
    if (IParent(_inlaw).getMarriageApproval(_wifeToBe)) {
      isMarried = true;
      wifeToBe = _wifeToBe;
      parentInLaw = _inlaw;
    }
  }

  function getEligibility() external view returns(bool) {
    require(msg.sender == address(jointBank), "HusbandToBe: unauthorized");
    return isMarried;
  }

  function createJointAccount() external onlyOwner {
    if(address(wifeToBe) == address(0)) revert NoMarriedYet();
    (bytes32 _accountId, bool success) = IBank(jointBank).createJointAccount(address(wifeToBe));
    require(success, "HusbandToBe: failed to create joint account");
    accountId = _accountId;
  }

  function checkBalance() public view onlyOwner returns (uint) {
    return IBank(jointBank).getBalance();
  }

  function signJointAccountCreation() public onlyOwner {
    bytes32 _accountId = accountId;
    require(
      IBank(jointBank).signJointAccountCreation(_accountId),
      "HusbandToBe: failed to sign joint account creation"
    );
  }

  function signWithdrawalRequest(uint amount) public onlyOwner {
    bytes32 _accountId = accountId;
    require(
      IBank(jointBank).signWithdrawalRequest(_accountId, amount),
      "HusbandToBe: failed to sign withdrawal request"
    );
  }

  function deposit() public payable onlyOwner {
    bytes32 _accountId = accountId;
    require(
      IBank(jointBank).deposit(_accountId),
      "HusbandToBe: failed to deposit"
    );
  }

  function initiateWithdrawal() public onlyOwner {
    require(
      IBank(jointBank).initiateWithdrawal(),
      "HusbandToBe: failed to initiate withdrawal"
    );
  }

  function cancelWithdrawalRequest() public onlyOwner {
    require(
      IBank(jointBank).cancelWithdrawalRequest(),
      "HusbandToBe: failed to cancel withdrawal request"
    );
  }

  function withdraw() public onlyOwner {
    IBank(jointBank).withdraw()
  }

  function _getAsset() internal view returns (address _asset) {
    _asset = address(profile.asset);
  }

  function _getBridePrice() internal view returns (uint _bridePrice) {
    _bridePrice = IParent(parentInLaw).getBridePrice();
  }

  function pause() public onlyOwner {
    _pause();
  }
  
  function unpause() public onlyOwner {
    _unpause();
  }
}