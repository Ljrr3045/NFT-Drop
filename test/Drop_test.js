const { expect, assert } = require("chai");
const { ethers } = require("hardhat");

describe ("Drop", async ()=> {
    let MyErc721, myErc721,MyErc1155, myErc1155, Drop, drop, owner, per1;

    before(async ()=>{
        MyErc721 = await ethers.getContractFactory("MyErc721");
        myErc721 = await MyErc721.deploy("ispf/","NoIspf");

        MyErc1155 = await ethers.getContractFactory("MyErc1155");
        myErc1155 = await MyErc1155.deploy("ispf/","NoIspf");

        Drop = await ethers.getContractFactory("Drop");
        drop = await Drop.deploy();

        [owner, per1, per2] = await ethers.getSigners();

        await myErc721.connect(owner).transferOwnership(drop.address);
        await myErc1155.connect(owner).transferOwnership(drop.address);

        await drop.connect(owner).const(myErc721.address, myErc1155.address);
    });

    describe("Confirming the start of the contract and minting status", async ()=> {
        it("Error: Should not start the cons function twice", async ()=> {
            await expect(drop.connect(owner).const(myErc721.address, myErc1155.address)).to.be.revertedWith("Contract be init");
        });

        it("Error: The mint state should not be reset", async ()=> {
            await drop.connect(owner).initMint(1);

            await expect(drop.connect(owner).initMint(0)).to.be.revertedWith("Set a grup mint");
        });

        it("Error: Only the owner can change the status of mint", async ()=> {
            await expect(drop.connect(per1).initMint(1)).to.be.reverted;
        });

        it("Should change the permission states to mint", async ()=> {
            assert(await drop.state() == 1);

            await drop.connect(owner).initMint(2);
            assert(await drop.state() == 2);
        });
    });

    describe("Confirming address return", async ()=> {
        it("Error: address does not exist", async ()=> {
            await  expect(drop.returnAdrresContract(3)).to.be.revertedWith("function was called with incorrect parameters");
        });

        it("Returns the addresses of the NFT contracts", async ()=> {
            expect(await drop.returnAdrresContract(0)).to.equal(myErc721.address);
            expect(await drop.returnAdrresContract(1)).to.equal(myErc1155.address);
        });
    });

    describe("Confirm role assignments", async ()=> {
        it("Owner should have the role owner and admin", async ()=> {
            expect(await drop.hasRole(ethers.utils.formatBytes32String("Admin"),owner.address)).to.equal(true);
            expect(await drop.hasRole(ethers.utils.formatBytes32String("Owner"),owner.address)).to.equal(true);
        });

        it("Admin should assign whitelist role", async ()=> {
            await drop.grantRole(ethers.utils.formatBytes32String("WhiteList"), per2.address);

            expect(await drop.hasRole(ethers.utils.formatBytes32String("WhiteList"),per2.address)).to.equal(true);
        });

        it("People should be able to assign the minter role", async ()=> {
            await drop.connect(per1).getRole();

            expect(await drop.hasRole(ethers.utils.formatBytes32String("Minter"),per1.address)).to.equal(true);
        });

        it("Error: Only admin can assign role", async ()=> {
            await expect(drop.connect(per2).grantRole(ethers.utils.formatBytes32String("WhiteList"), per1.address)).to.be.reverted;
        });

        after(async ()=> {
            await drop.connect(owner).initMint(1);
        })
    });

    describe("Checking the mint function", async ()=> {
        it("Error: should only mint if it's your role's turn", async ()=> {
            await expect(drop.connect(per1).mint(1, 5, 0, {value: ethers.utils.parseEther("0.01")})).to.be.reverted;
        });

        it("Error: should not mint if payment is not enough", async ()=> {
            await expect(drop.connect(per2).mint(1, 5, 0, {value: ethers.utils.parseEther("0.001")})).
            to.be.revertedWith("Pay is not enough for ERC721 Token");

            await expect(drop.connect(per2).mint(1, 5, 1, {value: ethers.utils.parseEther("0.001")})).
            to.be.revertedWith("Pay is not enough for ERC1155 Token");
        });

        it("Error: You shouldn't buy a token type that doesn't exist", async ()=> {
            await expect(drop.connect(per2).mint(1, 5, 3, {value: ethers.utils.parseEther("0.01")})).
            to.be.revertedWith("function was called with incorrect parameters");
        });

        it("User should be able to buy", async ()=> {
            await drop.connect(per2).mint(1, 5, 0, {value: ethers.utils.parseEther("0.02")});
            await drop.connect(owner).initMint(2);
            await drop.connect(per1).mint(1, 3, 1, {value: ethers.utils.parseEther("0.05")});

            expect(await myErc721.balanceOf(per2.address)).to.equal(1);
            expect(await myErc1155.balanceOf(per1.address, 1)).to.equal(3);
        });

        it("Should return the excess money", async ()=> {
            let balance = await ethers.provider.getBalance(drop.address);

            expect(balance).to.equal(ethers.utils.parseEther("0.04"));
        });

        it("Error: Only owner can withdraw the money", async ()=> {
            await expect(drop.connect(per1).withdraw()).to.be.reverted;
        });

        it("Owner should withdraw the money", async ()=> {
            await drop.connect(owner).withdraw();

            let balance = await ethers.provider.getBalance(drop.address);
            expect(balance).to.equal(ethers.utils.parseEther("0"));
        });
    });

    describe("Checking the burn function", async ()=> {
        it("Error: can only burn the owner of the token", async ()=> {
            await  expect(drop.connect(per1).burn(1, 5, 0)).to.be.revertedWith("You not is owner");
            await  expect(drop.connect(per2).burn(1, 2, 1)).to.be.revertedWith("You not is owner");
        });

        it("Error: only burn if there is approval", async ()=> {
            await  expect(drop.connect(per2).burn(1, 5, 0)).to.be.revertedWith("ERC721Burnable: caller is not owner nor approved");
            await  expect(drop.connect(per1).burn(1, 2, 1)).to.be.revertedWith("ERC1155: caller is not owner nor approved");
        });

        it("Should burn if there is approval", async ()=> {
            await myErc721.connect(per2).approve(drop.address, 1);
            await myErc1155.connect(per1).setApprovalForAll(drop.address, true);

            await drop.connect(per2).burn(1, 5, 0);
            await drop.connect(per1).burn(1, 2, 1);

            expect(await myErc721.balanceOf(per2.address)).to.equal(0);
            expect(await myErc1155.balanceOf(per1.address, 1)).to.equal(1);
        });

        after(async ()=> {
            await drop.connect(owner).initMint(1);
            await drop.connect(per2).mint(1, 5, 0, {value: ethers.utils.parseEther("0.01")});
        });
    });

    describe("Check if it shows the URI of each nft", async ()=> {
        it("Should show the hidden URI", async ()=> {
            expect(await myErc721.tokenURI(1)).to.equal("NoIspf");
            expect(await myErc1155.uri(1)).to.equal("NoIspf");
        });

        it("Should display the URI", async ()=> {
            await expect(drop.connect(per2).reveal()).to.be.reverted;

            await drop.connect(owner).reveal();

            expect(await myErc721.tokenURI(1)).to.equal("ispf/1.json");
            expect(await myErc1155.uri(1)).to.equal("ispf/1.json");
        });

        it("Error: Shouldn't display URI for nft that doesn't exist", async ()=> {
            await  expect(myErc721.tokenURI(4)).to.be.revertedWith("No existent token");
            await  expect(myErc1155.uri(4)).to.be.revertedWith("No existent token");
        });
    });
});