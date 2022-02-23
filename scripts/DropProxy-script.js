const { ethers, upgrades } = require("hardhat");

async function main() {

 let [owner, per1, per2] = await ethers.getSigners();

 let Drop = await ethers.getContractFactory("Drop");

 let MyErc721 = await ethers.getContractFactory("MyErc721");
 let myErc721 = await MyErc721.deploy(
   "ipfs://QmUppT7rzGe5LhansP1qjyZnwyGUkhjAzNTmCqz4HyEqGs/","ipfs://QmSDUnSwH4RSGkT7xoqFa75vgT15hMBKpCS7scx4bMk7Fi/hidden.png");

 let MyErc1155 = await ethers.getContractFactory("MyErc1155");
 let myErc1155 = await MyErc1155.deploy(
   "ipfs://QmUppT7rzGe5LhansP1qjyZnwyGUkhjAzNTmCqz4HyEqGs/","ipfs://QmSDUnSwH4RSGkT7xoqFa75vgT15hMBKpCS7scx4bMk7Fi/hidden.png");

 let drop = await upgrades.deployProxy(Drop, [myErc721.address, myErc1155.address], {initializer: "const"});

 await myErc721.transferOwnership(drop.address);
 await myErc1155.transferOwnership(drop.address);

 await drop.connect(owner).initMint(2);
 await drop.connect(per1).getRole();
 await drop.connect(per2).getRole();
 await drop.connect(per1).mint(1, 1, 0, {value: ethers.utils.parseEther("0.01")});
 await drop.connect(per2).mint(4, 1, 0, {value: ethers.utils.parseEther("0.01")});
 await drop.connect(per1).mint(3, 2, 1, {value: ethers.utils.parseEther("0.02")});
 await drop.connect(per2).mint(2, 3, 1, {value: ethers.utils.parseEther("0.03")});
 await drop.connect(owner).reveal();

 console.log("Address of Proxy Contract: ", drop.address);
 console.log("Address of ERC721 Contract: ", myErc721.address);
 console.log("Address of ERC1155 Contract: ", myErc1155.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
