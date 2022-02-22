const { expect, assert } = require("chai");
const { ethers } = require("hardhat");

describe("MyErc1155", async ()=> {
    let MyErc1155, myErc1155, owner, per1;

    before(async ()=>{
        MyErc1155 = await ethers.getContractFactory("MyErc1155");
        myErc1155 = await MyErc1155.deploy("ispf/","NoIspf");
        [owner, per1] = await ethers.getSigners();
    });

    describe("Testin mint function", async ()=> {
        it("Error: Only the owner can minter", async()=> {
            await expect(myErc1155.connect(per1).mint(per1.address, 1, 5)).to.be.revertedWith("Ownable: caller is not the owner");
        })

        it("Error: Can only mint in range", async ()=> {
            await expect(myErc1155.connect(owner).mint(per1.address, 15,5)).to.be.revertedWith("Not exist more token"); 
            await expect(myErc1155.connect(owner).mint(per1.address, 0,5)).to.be.revertedWith("Not exist more token");
        });

        it("Owner should mint", async ()=> {
            await myErc1155.connect(owner).mint(per1.address, 1, 5);

            let balance = await myErc1155.balanceOf(per1.address, 1);

            assert(balance.toNumber() === 5);
        });
    });

     describe("Testin burn function", async ()=> {
        it("Error: only the owner should burn", async ()=> {
            await expect(myErc1155.connect(per1).burn(per1.address, 1, 3)).to.be.revertedWith("Ownable: caller is not the owner");
        });

        it("Error: The owner should not burn without approval", async ()=> {
            await expect(myErc1155.connect(owner).burn(per1.address, 1, 3)).to.be.revertedWith("ERC1155: caller is not owner nor approved");
        });

        it("The owner should burn", async ()=> {
            await myErc1155.connect(per1).setApprovalForAll(owner.address,true);
            await myErc1155.connect(owner).burn(per1.address, 1, 3);

            let balance = await myErc1155.balanceOf(per1.address, 1);

            assert(balance.toNumber() === 2);
        });
    });

    describe("Testin tokenURI function", async ()=> {
        it("It should show a hidden image", async ()=> {
            expect(await myErc1155.uri(1)).to.equal("NoIspf");
        });

        it("It should show an image", async ()=> {
            await myErc1155.connect(owner).reveal();

            expect(await myErc1155.uri(1)).to.equal("ispf/1.json");
        });

        it("Error: If the token does not exist it should give an error", async ()=> {
           await expect(myErc1155.uri(2)).to.be.revertedWith("No existent token");
        });
    });
});
