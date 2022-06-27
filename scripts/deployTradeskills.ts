import { ethers } from "hardhat";

export const characterContract = "0x608f737f39F6a7b74A3ab1D5Fc2c2bb0c6fB0c3d";
//export const oreContract = "0xEe26E2055Fbb21a0B8961ce93953849a176f6E18";

async function main() {
    const Mining = await ethers.getContractFactory("Mining");
    const Ore = await ethers.getContractFactory("Ore");
    const characters = await ethers.getContractAt("OperatorFacet", characterContract);

    const signers = await ethers.getSigners();
    const accounts = signers.map((account) => account.address);

    const ore = await Ore.deploy();
    await ore.deployed();

    const mining: any = await Mining.deploy(ore.address, characterContract);
    await mining.deployed();

    await ore.addOperator(mining.address);
    await characters.addOperator(mining.address);

    console.log("Mining deployed to         ", mining.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
