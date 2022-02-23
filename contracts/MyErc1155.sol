// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**@title Contract for the ERC1155 token
  *@author ljrr3045
  *@notice This contract has all the functionality related to the erc1155 token
  *@dev Certain functions of this contract have a restricted access so that they can only be called by the owner, 
  therefore the ownership of the contract must be transferred to the "Drop" contract. 
  (This is done in this way, so that these functions can only be accessed from the "Drop" contract and nobody outside of it can access it). 
  Basic functions such as transferring, approving, etc... 
  Yes, they can and should be carried out from this contract.
*/

import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract MyErc1155 is ERC1155Pausable, Ownable{

    using Strings for uint256;

    string internal baseURI;
    string internal baseExtension = ".json";
    string internal notRevealedUri;
    bool internal revealed = false;
    mapping (uint256 => bool) public exist; //Mapping to find out if a token class exists.
    ///@dev These are variables to manage everything related to the URI that will be returned to ISPF


    ///@notice this contrscutor initializes both the erc1155 token, as well as the variables for the ISPF address
    constructor (string memory _baseURI, string memory _notRevealedUri) ERC1155(_baseURI){
        baseURI = _baseURI;
        notRevealedUri = _notRevealedUri;
    }

    //                                         *****FUNCTIONS*****

    //***Buy and burn***


  /**@notice This function is responsible for mint the token, it can only be accessed by the owner 
  (in our case it will be from the "Drop contract").
  *@dev In order to mint the token, an available token id between the range 1-6 must be selected.
  */
   function mint(address _to, uint256 _id, uint256 _amount) public onlyOwner {
        require(_id > 0 && _id <=6, "Not exist more token");
        _mint( _to, _id, _amount,""); 
        exist[_id] = true;
    }

  /**@notice This function is responsible for burning the token, it can only be accessed by the owner 
  (in our case it will be from the "Drop contract").
  *@dev In order to carry out the burning of the token, first the owner of the token must approve that the 
  "owner ("Drop contract")" can carry out the burning.
  */
   function burn(address account, uint256 id, uint256 value) public onlyOwner {
        require(account == _msgSender() || isApprovedForAll(account, _msgSender()), "ERC1155: caller is not owner nor approved");
        _burn(account, id, value);
    }


    //***Show URIs***


    /**@notice This function is responsible for returning the ISPF URI for openSea.
      *@dev while the "revealed" variable is false, return the URI for a hidden image
       first check if the token exists, in order to show its URI.
    */
    function uri(uint256 tokenId) public view virtual override returns (string memory){
        require(_exists(tokenId),"No existent token");
    
        if(revealed == false) {
        return notRevealedUri;
        }

        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString() , baseExtension)) : "";
    }

   ///@notice Function to enable the "token URI" function to return the true URI of the token and not hide it.
   ///@dev They can only be called by the owner.
   function reveal() public onlyOwner {
        revealed = true;
    }


    //***Pause and Unpause the contract***


    ///@notice Functions to pause and unpause the contract.
    ///@dev They can only be called by the owner.
    function pause() public onlyOwner{
        _pause();
    }

    function unpause() public onlyOwner{
        _unpause();
    }


    //***Other functions***  


    ///@dev Internal function to return the existence of a token.
    function _exists(uint256 _id) internal view returns(bool){
        return exist[_id]; 
    }
}