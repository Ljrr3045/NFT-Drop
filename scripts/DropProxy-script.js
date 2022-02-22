const { ethers, upgrades } = require("hardhat");

async function main() {

 let Drop = await ethers.getContractFactory("Drop");

 let MyErc721 = await ethers.getContractFactory("MyErc721");
 let myErc721 = await MyErc721.deploy("ispf/","NoIspf");

 let MyErc1155 = await ethers.getContractFactory("MyErc1155");
 let myErc1155 = await MyErc1155.deploy("ispf/","NoIspf");

 let drop = await upgrades.deployProxy(Drop, [myErc721.address, myErc1155.address], {initializer: "const"});

 await myErc721.transferOwnership(drop.address);
 await myErc1155.transferOwnership(drop.address);

 console.log("Address of Proxy Contract: ", drop.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
