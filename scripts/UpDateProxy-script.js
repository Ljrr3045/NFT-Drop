const { ethers, upgrades } = require("hardhat");

async function main() {
    let proxyAddress = "0xC3800f8b8043AD4C72629b1462FFeD920c8cA97a";
    let erc721Adrdress = "0x447aFf79eC207D4c0aCFF03d598e711FA18e0c0D";
    let erc1155Adrdress = "0x9F18cD6a4F503a9E7Fe4df92aC9A98113413ebe0";

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