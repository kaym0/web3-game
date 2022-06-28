import { run, ethers } from "hardhat";
import "@nomiclabs/hardhat-ethers";
// @ts-ignore
import { getSelectors, FacetCutAction } from "./libraries/diamond.js";
import { any } from "hardhat/internal/core/params/argumentTypes";
export const areaContract = "0x2402e2F36C4874bbe3082b5DCF502395B37AC2C1";
export const equipmentContract = "0xECB3e8575CECEdA7Ddfbab54488f86377DC330e3";
export const characterContract = "0x608f737f39F6a7b74A3ab1D5Fc2c2bb0c6fB0c3d";
export const gemsContract = "0xEe26E2055Fbb21a0B8961ce93953849a176f6E18";
export const marketContract = "0x08D9B6764d09612589fA73ddEC8D6B05F103f228";
export const tradeskillFactory = "0x43c6001DC1b625433011ae1D8Ec12ddF6b325334";

async function deploy() {
    const factory = await ethers.getContractAt("TradeskillFactory", tradeskillFactory);

    const tx = await factory.collect(2);
    const res = await tx.wait();

    console.log(res);

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
