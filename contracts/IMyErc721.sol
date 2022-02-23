// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**@title Interface for the ERC721 token
  *@author ljrr3045
  *@notice This interface contains the necessary functionalities to interact with 
   the "MyErc721" contract from the "Drop" contract.
*/

import "./MyErc721.sol";

interface IMyErc721 {
    function mint(address _to, uint256 _tokenId) external;
    function burn(uint256 tokenId) external;
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function reveal() external;
    function pause() external;
    function unpause() external;
} 