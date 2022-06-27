import { run, ethers } from "hardhat";
import "@nomiclabs/hardhat-ethers";

export const areaContract = "0x2526Df0e3B4AaC18bA3D4B652CBaCdd5708B1742";
export const equipmentContract = "0x90Df3CbA517DDb447b4B404cBd09f1098A3Af3A4";
export const characterContract = "0x9f9D6Fdfb1Da8ABD6F363Aa1fED939944Bd71F5c";
export const gemsContract = "0x7e3a688421bF6dADd0185324600a787f18E6f834";
export const marketContract = "0x250F9bd895350aAdDe700687F58B93209B101717";

async function deploy() {
    const market = await ethers.getContractAt("Marketplace", marketContract);

    const ore = await deploy("Ore");
    const fish = await deploy("Fish");
    const wood = await deploy("Wood");
    const stone = await deploy("Stone");

    await addMaterialId(market, "0", ore);
    await addMaterialId(market, "1", fish);
    await addMaterialId(market, "2", wood);
    await addMaterialId(market, "3", stone);

    console.log("Ore deployed to:           ", ore.address);
    console.log("Fish deployed to:          ", fish.address);
    console.log("Wood deployed to:          ", wood.address);
    console.log("Stone deployed to:         ", stone.address);

    async function addMaterialId(market: any, id: string, token: any) {
        const tx = await market.addMaterialId(id, token.address);
        await tx.wait();

        console.log("Token successfully added to marketplace.");
    }

    async function deploy(name: string, args: any[] = []) {
        const Factory = await ethers.getContractFactory(name);

        const contract = await Factory.deploy(...args);

        await contract.deployed();

        return contract;
    }
}

(async () => {
    try {
        await deploy();
        process.exit(0);
    } catch (error) {
        console.error(error);
        process.exit(1);
    }
})();
