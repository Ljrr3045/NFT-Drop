const { expect, assert } = require("chai");
const { ethers, upgrades } = require("hardhat");

describe ("UpGrade", async ()=> {
    let MyErc721, myErc721,MyErc1155, myErc1155, Drop, drop, DropV2, dropV2, owner, per1;

    before(async ()=>{
        Drop = await ethers.getContractFactory("Drop");
        DropV2 = await ethers.getContractFactory("DropV2");

        MyErc721 = await ethers.getContractFactory("MyErc721");
        myErc721 = await MyErc721.deploy("ispf/","NoIspf");

        MyErc1155 = await ethers.getContractFactory("MyErc1155");
        myErc1155 = await MyErc1155.deploy("ispf/","NoIspf");

        [owner, per1] = await ethers.getSigners();
    });

    it("Deploying update", async () => {
        drop = await upgrades.deployProxy(Drop, [myErc721.address, myErc1155.address], {initializer: "const"});

        await myErc721.connect(owner).transferOwnership(drop.address);
        await myErc1155.connect(owner).transferOwnership(drop.address);

        await drop.connect(owner).initMint(2);
        await drop.connect(per1).getRole();
        await drop.connect(per1).mint(1, 5, 0, {value: ethers.utils.parseEther("0.01")});

        dropV2 = await upgrades.upgradeProxy(drop.address, DropV2);
        
        await dropV2.const(myErc721.address, myErc1155.address);
        expect(await dropV2.balanceOf(owner.address)).to.be.equal(50);

        await dropV2.connect(owner).reveal();
        expect(await myErc721.tokenURI(1)).to.equal("ispf/1.json");
      });
});