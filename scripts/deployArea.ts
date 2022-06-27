import { ethers } from "hardhat";

export const characterContract = "0x608f737f39F6a7b74A3ab1D5Fc2c2bb0c6fB0c3d";
export const gemsContract = "0xEe26E2055Fbb21a0B8961ce93953849a176f6E18";

async function main() {
    const Area = await ethers.getContractFactory("AreaFactory");

    const signers = await ethers.getSigners();
    const accounts = signers.map((account) => account.address);
    const area: any = await Area.deploy(characterContract, gemsContract);
    // Await deployment.

    await area.deployed();

    console.log("AreaFactory deployed to:      ", area.address);
    /////// [ AreaID, Difficulty, Exp/Day, Gems/Day, Drops/Day]
    await createArea(area, "1", "30", "500", "400", "1");
    await createArea(area, "2", "20", "691200", "172800", "1");
    await createArea(area, "3", "20", "1342400", "345600", "1");

    console.log("AreaFactory deployed to:      ", area.address);

    async function createArea(
        area: any,
        areaId: string,
        difficulty: string,
        expDay: string,
        gemsDay: string,
        dropsDay: string
    ) {
        const tx = await area.createArea(areaId, difficulty, expDay, gemsDay, dropsDay);
        const response = await tx.wait();

        // Notify response.
        console.log(response);
    }
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
