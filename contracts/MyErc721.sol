// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MyErc721 is ERC721Pausable, Ownable{

    using Strings for uint256;

    string public baseURI;
    string public baseExtension = ".json";
    string public notRevealedUri;
    bool public revealed = false;
    

    constructor(string memory _baseURI, string memory _notRevealedUri) ERC721("Kimetzu721", "KMZ721"){
      baseURI = _baseURI;
      notRevealedUri = _notRevealedUri;
    }

    function burn(uint256 tokenId) public onlyOwner {
      require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721Burnable: caller is not owner nor approved");
      _burn(tokenId);
    }

    function mint(address _to, uint256 _tokenId) public onlyOwner {
      require(_tokenId > 0 && _tokenId <=10, "Not exist more token");
      _mint(_to,_tokenId);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory){
      require(_exists(tokenId),"No existent token");
    
      if(revealed == false) {
      return notRevealedUri;
      }

      return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString() , baseExtension)) : "";
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
}