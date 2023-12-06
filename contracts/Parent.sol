// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./interfaces/IBank.sol";
import "./interfaces/IParent.sol";
import "./interfaces/IWifeToBe.sol";
import "./interfaces/IHusbandToBe.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";

// Parent are like Bank, in real world, a trusted third part is required to goven the activities.
contract Parent is IParent, Ownable, Pausable {
  IBank private bank;

  IERC20 private asset;

  uint private bridePrice;

  bool private initialized;

  mapping (address => Daughter) public daughters;

  mapping (address => bool) public paymentApprovals;

  modifier onlyDaughter() {
    require(daughters[msg.sender].isOurDaugther, "Parent: not related");
    _;
  }

  modifier isInitizlized() {
    require(initialized, "Parent: contract not initialized");
    _;
  }

  constructor(IBank _bank, uint _bridePrice) {
    bridePrice = _bridePrice;
    if (address(_bank) == address(0)) revert InvalidBankAddress();
    initialized = false;
  }

  receive() external payable {
    require(msg.value > 0);
  }

  function initiazlie(IWifeToBe[] memory _daughters) public onlyOwner {
    require(!initialized, "Parent: already initialized");
    initialized = true;
    for (uint i = 0; i < _daughter.slength; i++) {
      daughters[address(_daughters[i])].isOurDaugther = true;
    }
  }

  function approveToPayBridePrice(
    IHusbandToBe proposer,
    IWifeToBe proposedTo
  ) public onlyOwner isInitizlized {
    address _husband = address(proposer);
    if (daughters[address(proposedTo)].pricePaymentApproved) {
      revert ApprovalAlreadyGivenToSomeone();
    }
    if (paymentApprovals[_husband]) {
      revert ProposerAlreadyApproved(_husband);
    }
    paymentApprovals[_husband] = true;
  }

  function getMarriageApproval(IWifeToBe _daughter)
    external
    whenNotPaused
    isInitizlized
    onlyDaughter(address(_daughter))
    returns (bool _approval)
    {
      uint _bridePrice = IERC20(_getAsset()).allowance(
        _msgSender(),
        address(this)
      );
      if (!paymentApprovals[_msgSender()]) {
        revert NotApprovedForPricePayment(_msgSender());
      }
      if (_bridePrice < bridePrice) {
        revert InsufficientBridePrice();
      }
      if (IERC20(_getAsset()).transferFrom(
        _msgSender(),
        address(this),
        bridePrice
      )) {
        address daughter = address(_daughter);

        daughters[daughter].marriedTo = IHusbandToBe(_msgSender());
        daughters[daughter].bridePrice = _bridePrice;
        require(
          IWifeToBe(_daughter).setMarriageStatus(IHusbandToBe(_msgSender())),
          "Parent: marriage status updated"
        );
        _approval = true;
      }
    }

    function adjustBridePrice(uint _newBridePrice) public onlyOwner {
      bridePrice = _newBridePrice;
    }

    function spendMoney(address to, uint amount) public onlyOwner isInitizlized {
      require(IERC20(_getAsset()).transfer(to, amount), "Parent: transfer failed");
    }

    function _getAsset() internal view returns(IERC20) {
      return asset;
    }

    function _getBridePrice() internal view returns(uint) {
      return bridePrice;
    }

    function pause() public onlyOwner {
      _pause();
    }

    function unpaused() public onlyOwner {
      _unpause();
    }

    function getEligibility() external view returns(bool) {}
}