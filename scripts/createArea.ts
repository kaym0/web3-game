import { ethers } from "hardhat";

async function main() {
    const area = await ethers.getContractAt(
        "AreaFactory",
        "0x2526Df0e3B4AaC18bA3D4B652CBaCdd5708B1742"
    );

    // Await deployment.
    const tx = await area.createArea(
        "2", //// AreaID
        "20", //// Difficulty
        "691200", //// Daily Exp
        "172800", //// Daily Gems
        "1" //// Daily Drops
    );
    const response = await tx.wait();
    // console.log(response);
    // console.log(tx);
    
    const index = await area.index();
    const expRate = await area.expRate("2");
    const gemRate = await area.gemRate("2");
    const difficulty = await area.difficulty("2");
    
    console.log("Index:        ", index)
    console.log("Exp rate:     ", expRate);
    console.log("Gem rate:     ", gemRate);
    console.log("Difficulty:   ", difficulty);

    console.log("AreaFactory deployed to:      ", area.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
