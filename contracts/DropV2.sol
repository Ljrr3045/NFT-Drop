// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**@title This contract is version 2 of the Drop contract
  *@author ljrr3045
  *@notice This contract is different from its version 1, which allows users to buy an ERC20 token 
  in order to buy their NFTs. These ERC20 tokens can be exchanged freely.
  */

import "./IMyErc721.sol";
import "./IMyErc1155.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";

contract DropV2 is AccessControlUpgradeable, ERC20Upgradeable {

    enum Stand {erc721, erc1155}
    enum State {nobody, whiteList, allMinter}
    State public state;

    uint private _init;
    address internal _Owner;
    IMyErc721 _Erc721;
    IMyErc1155 _Erc1155;

    modifier confirmState(){
        require(state == State.whiteList || state == State.allMinter, "Mint Not Start");
        _;
    }

    /**@dev The constructor function is modified a bit so that when it is called a second time 
       (that is, when it is updated) it takes care of initializing only the ERC20 token. 
    */
    function const(address _adreErc721, address _adreErc1155) initializer() public {
        require (_init == 0 || _init == 1,"Contract be init");

        if(_init == 0){
        _Owner = msg.sender;

        _setupRole("Admin", msg.sender);
        _setupRole("Owner", _Owner);
        _setRoleAdmin("Admin", "Admin");
        _setRoleAdmin("Minter", "Admin");
        _setRoleAdmin("whiteList", "Admin");
        _setRoleAdmin("Owner", "Owner");

        _Erc721 = IMyErc721(_adreErc721);
        _Erc1155 = IMyErc1155(_adreErc1155);

        state = State.nobody;

        _init++;
        }

        if(_init == 1){
        __ERC20_init("KimetzuERC20", "KMZ20");
        _mint(_Owner, 50);
        _init++;
        } 
    }

    function initMint(State _state) external onlyRole("Admin"){
        require(_state != State.nobody, "Set a grup mint");
        state = _state;
    }

    function mint(uint256 _id, uint256 _amount,Stand _stand) external confirmState(){
        if(state == State.whiteList){
            _checkRole("whiteList", msg.sender);
            _mintDrop(_id, _amount,_stand);
        }else{
            _checkRole("Minter", msg.sender);
            _mintDrop(_id, _amount,_stand);
        }
    }

    function burn(uint256 _id, uint256 _amount, Stand _stand) public {
        if(_stand == Stand.erc721){
            require(_Erc721.ownerOf(_id) == msg.sender, "You not is owner");
            _Erc721.burn(_id);
        } else{
            require(_Erc1155.balanceOf(msg.sender,_id) > 0,"You not is owner");
            _Erc1155.burn(msg.sender,_id, _amount);
        }
    }

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

    function getRole() public {
        _grantRole("Minter", msg.sender);
    }

    function returnAdrresContract(Stand _stand) public view returns(address){
        if(_stand == Stand.erc721){
            return address(_Erc721);
        } else{
            return address(_Erc1155);
        }
    }

    function withdraw() public onlyRole("Owner"){
        payable(_Owner).transfer(address(this).balance);
    }

    //***New functions***

    /**@notice Function that allows any user to buy the ERC20 token, as long as the minimum payment amount 
       is 0.001 ether (price of each token).
    */
    function buyToken20() public payable{
        require(msg.value >= 0.001 ether, "Not enaug mony for buy tokens");
        uint tokenConvertion = msg.value / 0.001 ether;
        _mint(msg.sender, tokenConvertion);
    }

    /**@notice Function in charge of the mint of the NFT, the amount of ERC20 tokens to cancel will be automatically 
       deducted from the user's account, in case of not having enough token balance the operation will fail.
    */
    function _mintDrop(uint256 _id, uint256 _amount,Stand _stand) internal{
        uint totalPay;

        if(_stand == Stand.erc721){
            totalPay = 60;
            _transfer(msg.sender, _Owner, totalPay);
            _Erc721.mint(msg.sender,_id);

        } else{
            totalPay = 60 * _amount;
            _transfer(msg.sender, _Owner, totalPay);
            _Erc1155.mint(msg.sender,_id, _amount); 
        }
    }
}