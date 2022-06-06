import { ethers } from "hardhat";

async function main() {
    const Characters = await ethers.getContractFactory("Characters");

    const characters = Characters.attach("0x6C642597929F39dEed9150C27B312aF8b363862E");

    const tx = await characters.getCharactersOfOwner("0x94CC285EAf470aBd3D0976C7Dfb8BC862c3Cf71F");

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
