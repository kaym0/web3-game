import { ethers } from "hardhat";

async function main() {
    const Equipment = await ethers.getContractFactory("DreamEquipment");

    const signers = await ethers.getSigners();
    const accounts = signers.map(((account) => account.address ));
    const equipment: any = Equipment.attach("0xe24E7A1B5fDed28EdAA704d0742462acC1F65319");
    const tx = await equipment.getEquipmentOfOwner(accounts[0]);


    console.log(tx);

    //console.log("Equipment deployed to:", equipment.address);
    //console.log("Characters deployed to:", characters.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});