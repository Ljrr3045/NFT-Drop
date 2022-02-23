// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**@title This is the main contract, the Drop contract
  *@author ljrr3045
  *@notice This contract is responsible for managing all the sale and burning of the ERC721 and ERC1155 tokens. 
  For a person to be able to participate, only the Mint role must be assigned, also if a person wants to participate 
  in the purchase of some NFT before time, then only the admin must assign him the "Whitelist" role so that he can 
  participate in this previous sale.
  *@dev ***Read the Notes***
  
  Note 1: I am very aware that a better way to design this contract was to deploy the contracts "MyERC721" and "MyERC1155" 
  from here, but when doing this it happens that this contract exceeds the size of the ByteCode, therefore I resort to apply this 
  form of design where the address of the contracts to be instantiated is passed as parameters.

  Note 2: This is an upgradeable contract where the purchase of the NFT is made with ether; its version 2 (DropV2) makes this NFT 
  purchase with a native ERC20 token. Therefore, for everything to work correctly at the time of updating, this contract must also 
  inherit the Oz contract "ERC20Upgradeable", otherwise an incompatibility error occurs at the time of updating due to the implementation 
  of this ERC20 token (In In the first instance this contract was not planned to inherit "ERC20Upgradeable", but in order to perform 
  this upgrade, it had to).
*/

import "./IMyErc721.sol";
import "./IMyErc1155.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";

contract Drop is AccessControlUpgradeable, ERC20Upgradeable {

    enum Stand {erc721, erc1155}
    enum State {nobody, whiteList, allMinter}
    State public state;

    uint private _init;
    address internal _Owner;
    IMyErc721 _Erc721;
    IMyErc1155 _Erc1155;
    /**@notice Enum in charge of managing the state of the contract and variables to install contracts and save the address 
    of the owner of the contract*/


    //                                        *****MODIFIERS*****

    ///@notice this modifier is in charge of verifying if the process to mint has been started
    modifier confirmState(){
        require(state == State.whiteList || state == State.allMinter, "Mint Not Start");
        _;
    }


    //                                         *****FUNCTIONS*****


    //***Initializers***

    /**@notice Function in charge of initializing the variables and roles for the users, in addition to 
       initiating the contracts for the ERC721 and ERC1155. It needs the addresses of ERC721 and ERC1155 as parameters.
       *@dev Can only call this function once.
    */
    function const(address _adreErc721, address _adreErc1155) public {
        require (_init == 0,"Contract be init");
        _Owner = msg.sender;

        _setupRole("Admin", msg.sender);
        _setupRole("Owner", _Owner);
        _setRoleAdmin("Admin", "Admin");
        _setRoleAdmin("Minter", "Admin");
        _setRoleAdmin("WhiteList", "Admin");
        _setRoleAdmin("Owner", "Owner");

        _Erc721 = IMyErc721(_adreErc721);
        _Erc1155 = IMyErc1155(_adreErc1155);

        state = State.nobody;
        _init++;
    }

    ///@notice Function to modify the state of the contract. Allow purchase to users with WhiteList or Mint role
    function initMint(State _state) external onlyRole("Admin"){
        require(_state != State.nobody, "Set a grup mint");
        state = _state;
    }


    //***Buy and burn***

    /**@notice Function in charge of mint the NFT, it is a payment function, where depending on the status of 
       the contract and the role of the user, you can mint an ERC721 or ERC1155 token.
       *@dev To perform the mint, this function calls an internal _mint function. 
    */
    function mint(uint256 _id, uint256 _amount,Stand _stand) external payable confirmState(){
        if(state == State.whiteList){
            _checkRole("WhiteList", msg.sender);
            _mint(_id, _amount,_stand);
        }else{
            _checkRole("Minter", msg.sender);
            _mint(_id, _amount,_stand);
        }
    }

    /**@notice This function is in charge of burning tokens, only the user who owns the token will be the one who can burn it
      *@dev In order to burn, the user must first approve that the "Drop" contract can burn their ERC721 or ERC1155 token.
    */
    function burn(uint256 _id, uint256 _amount, Stand _stand) public {
        if(_stand == Stand.erc721){
            require(_Erc721.ownerOf(_id) == msg.sender, "You not is owner");
            _Erc721.burn(_id);
        } else{
            require(_Erc1155.balanceOf(msg.sender,_id) > 0,"You not is owner");
            _Erc1155.burn(msg.sender,_id, _amount);
        }
    }


    //***Pause, Unpause and Show URIs***

    /**@dev Functions to pause and unpause the ERC721 and ERC1155 contracts, as well as a function to reveal the URIs 
       of the ERC721 and ERC1155 tokens.
    */
    function pause() public onlyRole("Admin"){
        _Erc721.pause();
        _Erc1155.pause();
    }

    function unPause() public onlyRole("Admin"){
        _Erc721.unpause();
        _Erc1155.unpause();
    }

    function reveal() public onlyRole("Admin"){
        _Erc721.reveal();
        _Erc1155.reveal();
    }


    //***Utility functions***

    ///@notice Function so that the user assigns himself the "Minter" role and can buy tokens (Without this role you cannot buy)
    function getRole() public {
        _grantRole("Minter", msg.sender);
    }

    /**@notice Function that returns to users the addresses of the contracts of the ERC721 and ERC1155 tokens.
       So that users can go and interact with the other functions of the tokens.
    */
    function returnAdrresContract(Stand _stand) public view returns(address){
        if(_stand == Stand.erc721){
            return address(_Erc721);
        } else{
            return address(_Erc1155);
        }
    }

    /**@notice Function that allows the owner of the contract to withdraw all the funds generated from the sale of the tokens.
      *@dev Only the owner can access it.
    */
    function withdraw() public onlyRole("Owner"){
        payable(_Owner).transfer(address(this).balance);
    }


    //***Internals functions***

    /**@notice Function in charge of managing the mining of tokens
      *@dev Check what is the standard and the amount of tokens and based on it calculates the total amount to pay, 
      if the customer's payment exceeds the total price, the surplus is returned and if the customer pays much less than 
      the total amount, it is proceeds to cancel the operation 
    */
    function _mint(uint256 _id, uint256 _amount,Stand _stand) internal{
        if(_stand == Stand.erc721){

            require(msg.value >= 0.01 ether, "Pay is not enough for ERC721 Token");
            _Erc721.mint(msg.sender,_id);
            
            if(msg.value > 0.01 ether){
                payable(msg.sender).transfer(msg.value - 0.01 ether);
            }
        } else{
            require(msg.value >= _amount * 0.01 ether, "Pay is not enough for ERC1155 Token");
            _Erc1155.mint(msg.sender,_id, _amount);

            if(msg.value > _amount * 0.01 ether){
                payable(msg.sender).transfer(msg.value - _amount * 0.01 ether);
            }
        }
    }
}
