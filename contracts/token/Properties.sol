// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract Properties is IERC721 {
  uint public tokenId;
  uint public mintFee;

  constructor() ERC721("Properties", "PRO") {
    for (uint i = 0; i < 11; i++) {
      tokenId += i;
      _safeMint(msg.sender, i);
    }
  }

  function safeMint() external payable returns (bool) {
    require(msg.value > mintFee, "Properties: insufficient fee");
    tokenId += 1;
    _safeMint(msg.sender, tokenId);
    return true;
  }
}