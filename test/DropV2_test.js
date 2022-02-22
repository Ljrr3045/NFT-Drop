const { expect, assert } = require("chai");
const { ethers } = require("hardhat");

/* The rest of "DropV2" functions were tested in the "Drop_test.js" file */

describe ("DropV2", async ()=> {
    let MyErc721, myErc721,MyErc1155, myErc1155, DropV2, dropV2, owner, per1;

    before(async ()=>{
        MyErc721 = await ethers.getContractFactory("MyErc721");
        myErc721 = await MyErc721.deploy("ispf/","NoIspf");

        MyErc1155 = await ethers.getContractFactory("MyErc1155");
        myErc1155 = await MyErc1155.deploy("ispf/","NoIspf");

        DropV2 = await ethers.getContractFactory("DropV2");
        dropV2 = await DropV2.deploy();

        [owner, per1, per2] = await ethers.getSigners();

        await myErc721.connect(owner).transferOwnership(dropV2.address);
        await myErc1155.connect(owner).transferOwnership(dropV2.address);

        await dropV2.connect(owner).const(myErc721.address, myErc1155.address);
        await dropV2.connect(owner).initMint(2);
        await dropV2.connect(per1).getRole();
        await dropV2.connect(per2).getRole();
    });

    describe("Checking the ERC20 token purchase", async ()=> {
        it("Error: You should not buy token if there is not enough payment", async ()=> {
            await expect(dropV2.connect(per1).buyToken20({value: ethers.utils.parseEther("0.000001")})).
            to.be.revertedWith("Not enaug mony for buy tokens");
        });

        it("Should buy token if there is enough payment", async ()=> {
            await dropV2.connect(per1).buyToken20({value: ethers.utils.parseEther("1")});
            
            expect(await dropV2.balanceOf(per1.address)).to.be.equal(1000);
            expect(await dropV2.balanceOf(owner.address)).to.be.equal(50);
        });
    });

    describe("Check the purchase system with ERC20 Token", async ()=> {
        it("Error: Should not buy if there is not enough balance", async ()=> {
            await expect(dropV2.connect(per2).mint(1,4,0)).to.be.revertedWith("ERC20: transfer amount exceeds balance");
        });

        it("Should buy if funds are available", async ()=> {
            await dropV2.connect(per1).mint(1,4,0);
            await dropV2.connect(per1).mint(1,2,1);

            expect(await dropV2.balanceOf(per1.address)).to.be.equal(820);
            expect(await dropV2.balanceOf(owner.address)).to.be.equal(230);
            expect(await myErc1155.balanceOf(per1.address, 1)).to.be.equal(2);
            expect(await myErc721.ownerOf(1)).to.be.equal(per1.address);
        });
    });
});