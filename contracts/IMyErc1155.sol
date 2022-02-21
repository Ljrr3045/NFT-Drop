// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "./MyErc1155.sol";

interface IMyErc1155 {
    function mint(address _to, uint256 _id, uint256 _amount) external;
    function burn(address account, uint256 id, uint256 value) external;
    function reveal() external;
    function pause() external;
    function unpause() external;
}