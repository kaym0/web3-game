import { ethers } from "hardhat";

async function main() {
    const Area = await ethers.getContractFactory("Area");

    const signers = await ethers.getSigners();
    const accounts = signers.map(((account) => account.address ));
    const area: any = Area.attach("0xd6d686Bfb839a8291bb94e2020905Ca583Ce2712");
    const tx = await area.enter("0");

    const response = await tx.wait();

    
    console.log(response);


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