// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract MyErc1155 is ERC1155Pausable, Ownable{

    using Strings for uint256;

    string internal baseURI;
    string public baseExtension = ".json";
    string public notRevealedUri;
    bool public revealed = false;
    mapping (uint256 => bool) public exist;

    constructor (string memory _baseURI, string memory _notRevealedUri) ERC1155(_baseURI){
        baseURI = _baseURI;
        notRevealedUri = _notRevealedUri;
    }

   function uri(uint256 tokenId) public view virtual override returns (string memory){
    require( _exists(tokenId),"Nonexistent token");
    
    if(revealed == false) {
        return notRevealedUri;
    }

    return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString() , baseExtension)) : "";
    }

   function mint(address _to, uint256 _id, uint256 _amount) public onlyOwner {
        require(_id > 0 && _id <=10, "Not exist more token");
        _mint( _to, _id, _amount,""); 
        exist[_id] = true;
    }

   function burn(address account, uint256 id, uint256 value) public onlyOwner {
        require(account == _msgSender() || isApprovedForAll(account, _msgSender()), "ERC1155: caller is not owner nor approved");
        _burn(account, id, value);
    }

   function reveal() public onlyOwner {
      revealed = true;
    }

    function pause() public onlyOwner{
        _pause();
    }

    function unpause() public onlyOwner{
        _unpause();
    }  

    function _exists(uint256 _id) internal view returns(bool){
      return exist[_id]; 
    }
}