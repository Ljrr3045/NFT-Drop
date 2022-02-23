// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**@title Interface for the ERC1155 token
  *@author ljrr3045
  *@notice This interface contains the necessary functionalities to interact with 
   the "MyErc1155" contract from the "Drop" contract.
*/

import "./MyErc1155.sol";

interface IMyErc1155 {
    function mint(address _to, uint256 _id, uint256 _amount) external;
    function burn(address account, uint256 id, uint256 value) external;
    function balanceOf(address account, uint256 id) external view returns (uint256);
    function reveal() external;
    function pause() external;
    function unpause() external;
}