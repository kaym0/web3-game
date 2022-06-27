import { run, ethers } from "hardhat";
import "@nomiclabs/hardhat-ethers";
// @ts-ignore
import { getSelectors, FacetCutAction } from "./libraries/diamond.js";
import { any } from "hardhat/internal/core/params/argumentTypes";

export const areaContract = "0x56F983D8821D097E3a1435Ed486E979dBBe27EA9";
export const equipmentContract = "0x4A443a1ba7FAD407697CFcEFF59E62Be7e1fdc57";
export const characterContract = "0x06223aEA47F97694Fda88D9FDB98646943ba70C2";
export const gemsContract = "0x7c27a1A456bd471Ac004ed330DfA8A3044CFF5f8";
export const marketContract = "0x4952a8bA98908c1062e8a4250423db7534D42EFe";

async function deploy() {
    const area = await ethers.getContractAt("AreaFactory", areaContract);


    const tx = await area.testRates("1", "5");

    console.log(tx)
    async function addOperator(contract: any, operator: any) {
        const tx = await contract.addOperator(operator);
        await tx.wait();
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
