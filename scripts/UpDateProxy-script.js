const { ethers, upgrades } = require("hardhat");

async function main() {
    let proxyAddress; //insert address
    let erc721Adrdress; //insert address
    let erc1155Adrdress; //insert address

    const DropV2 = await ethers.getContractFactory("DropV2");

    let dropV2 = await upgrades.upgradeProxy(proxyAddress, DropV2);

    await dropV2.const(erc721Adrdress, erc1155Adrdress);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
});