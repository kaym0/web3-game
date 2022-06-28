import { ethers } from "hardhat";

export const characterContract = "0x608f737f39F6a7b74A3ab1D5Fc2c2bb0c6fB0c3d";

async function main() {
    const characters = await ethers.getContractAt("OperatorFacet", characterContract);

    /// Deploy tokens, then the skill.
    const ore = await deploy("Ore");
    const fish = await deploy("Fish");
    const wood = await deploy("Wood");
    const stone = await deploy("Stone");
    const factory = await deploy("TradeskillFactory", [characters.address]);

    /// Adds operator status to material contracts so the tradeskill factory can mint them
    await addOperator(ore, factory.address);
    await addOperator(fish, factory.address);
    await addOperator(wood,  factory.address);
    await addOperator(stone, factory.address);
    await addOperator(characters, factory.address);



    await addTradeskill(factory, "1", ore.address)
    await addTradeskill(factory, "2", fish.address)
    await addTradeskill(factory, "3", wood.address)
    await addTradeskill(factory, "4", stone.address)

    console.log(`export const oreContract       = "${ore.address}"`)
    console.log(`export const fishContract      = "${fish.address}"`)
    console.log(`export const woodContract      = "${wood.address}"`)
    console.log(`export const stoneContract     = "${stone.address}"`)
    console.log(`export const tradeskillFactory = "${factory.address}"`)

    async function addOperator(contract: any, operator: string) {
        const tx = await contract.addOperator(operator);
        await tx.wait();
        return;
    }

    async function deploy(name: string, args: any[] = []) {
        const Factory = await ethers.getContractFactory(name);

        const contract = await Factory.deploy(...args);

        await contract.deployed();

        return contract;
    }

    async function addTradeskill(contract: any, id: string, materialAddress: string) {
        const tx  = await contract.updateTradeskill(id, materialAddress);
        const res = await tx.wait();
    }
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
