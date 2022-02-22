// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "./IMyErc721.sol";
import "./IMyErc1155.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";

contract Drop is AccessControlUpgradeable, ERC20Upgradeable {

    enum Stand {erc721, erc1155}
    enum State {nobody, whiteList, allMinter}
    State public state;

    uint private timeWhiteListMint;
    uint private _init;
    address internal _Owner;
    IMyErc721 _Erc721;
    IMyErc1155 _Erc1155;
    

    modifier confirmState(){
        require(state == State.whiteList || state == State.allMinter, "Mint Not Start");
        _;
    }

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

    function initMint(State _state) external onlyRole("Admin"){
        require(_state != State.nobody, "Set a grup mint");
        state = _state;
    }

    function mint(uint256 _id, uint256 _amount,Stand _stand) external payable confirmState(){
        if(state == State.whiteList){
            _checkRole("WhiteList", msg.sender);
            _mint(_id, _amount,_stand);
        }else{
            _checkRole("Minter", msg.sender);
            _mint(_id, _amount,_stand);
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

    function reveal() public onlyRole("Admin"){
        _Erc721.reveal();
        _Erc1155.reveal();
    }

    function pause() public onlyRole("Admin"){
        _Erc721.pause();
        _Erc1155.pause();
    }

    function unPause() public onlyRole("Admin"){
        _Erc721.unpause();
        _Erc1155.unpause();
    }

    function getRole() public {
        _grantRole("Minter", msg.sender);
    }

    function withdraw() public onlyRole("Owner"){
        payable(_Owner).transfer(address(this).balance);
    }

    function returnAdrresContract(Stand _stand) public view returns(address){
        if(_stand == Stand.erc721){
            return address(_Erc721);
        } else{
            return address(_Erc1155);
        }
    }

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
