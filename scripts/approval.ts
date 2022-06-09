import { ethers } from "hardhat";

async function main() {
    const Equipment = await ethers.getContractFactory("DreamEquipment");

    const signers = await ethers.getSigners();
    const accounts = signers.map(((account) => account.address ));
    const equipment: any = Equipment.attach("0x5836C897a2221A90E126EBd9B9D14577454f2543");

    const tx = await equipment.setApprovalForAll("0x4C585a5E977758C83523A6578cC19120BE8EfC4E", true)
    await tx.wait();

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