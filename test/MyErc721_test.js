const { expect, assert } = require("chai");
const { ethers } = require("hardhat");

describe("MyErc721", async ()=> {
    let MyErc721, myErc721, owner, per1;

    before(async ()=>{
        MyErc721 = await ethers.getContractFactory("MyErc721");
        myErc721 = await MyErc721.deploy("ispf/","NoIspf");
        [owner, per1] = await ethers.getSigners();
    });

    describe("Testin mint function", async ()=> {
        it("Error: Only the owner can minter", async()=> {
            await expect(myErc721.connect(per1).mint(per1.address, 1)).to.be.revertedWith("Ownable: caller is not the owner");
        })

        it("Error: Can only mint in range", async ()=> {
            await expect(myErc721.connect(owner).mint(per1.address, 15)).to.be.revertedWith("Not exist more token"); 
            await expect(myErc721.connect(owner).mint(per1.address, 0)).to.be.revertedWith("Not exist more token");
        });

        it("Owner should mint", async ()=> {
            await myErc721.connect(owner).mint(per1.address, 1);

            let balance = await myErc721.balanceOf(per1.address);

            assert(balance.toNumber() === 1);
        });
    });

    describe("Testin burn function", async ()=> {
        it("Error: only the owner should burn", async ()=> {
            await expect(myErc721.connect(per1).burn(1)).to.be.revertedWith("Ownable: caller is not the owner");
        });

        it("Error: The owner should not burn without approval", async ()=> {
            await expect(myErc721.connect(owner).burn(1)).to.be.revertedWith("ERC721Burnable: caller is not owner nor approved");
        });

        it("The owner should burn", async ()=> {
            await myErc721.connect(per1).approve(owner.address, 1);
            await myErc721.connect(owner).burn(1);

            let balance = await myErc721.balanceOf(per1.address);

            assert(balance.toNumber() === 0);
        });
    });

    describe("Testin tokenURI function", async ()=> {
        it("It should show a hidden image", async ()=> {
            await myErc721.connect(owner).mint(per1.address, 1);

            expect(await myErc721.tokenURI(1)).to.equal("NoIspf");
        });

        it("It should show an image", async ()=> {
            await myErc721.connect(owner).reveal();

            expect(await myErc721.tokenURI(1)).to.equal("ispf/1.json");
        });

        it("Error: If the token does not exist it should give an error", async ()=> {
           await expect(myErc721.tokenURI(2)).to.be.revertedWith("No existent token");
        });
    });
});
