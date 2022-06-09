import { ethers } from "hardhat";

async function main() {
    const signers = await ethers.getSigners();
    const accounts = signers.map((account) => account.address);

    const equipment = await deploy("Equipment");
    const characters = await deploy("Characters");
    const gems = await deploy("Gems");
    const area = await deploy("Area", [characters.address, gems.address, "500"]);
    const market = await deploy("Marketplace", [equipment.address, gems.address]);

    await initialize(characters, equipment);
    await addOperator(equipment, characters.address);
    await addOperator(characters, equipment.address);
    await addOperator(gems, area.address);
    await addOperator(characters, area.address);

    await createTestEquipment(equipment, 12);

    console.log("Equipment deployed to:             ", equipment.address);
    console.log("Characters deployed to:            ", characters.address);
    console.log("Gems deployed to:                  ", gems.address);
    console.log("Area deployed to:                  ", area.address);
    console.log("Market deployed to:                ", market.address);

    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    async function deploy(name: string, args: any[] = []) {
        const Factory = await ethers.getContractFactory(name);

        const contract = await Factory.deploy(...args);

        await contract.deployed();

        return contract;
    }

    async function initialize(characters: any, equipment: any) {
        const tx = await characters.initialize(equipment.address);
        await tx.wait();
    }

    async function addOperator(contract: any, operator: any) {
        const tx = await contract.addOperator(operator);
        await tx.wait();
    }

    async function createTestEquipment(equipment: any, amount: number) {
        const equipmentNames = [
            "Melding of the Flesh",
            "Aegis Aurora",
            "Mageblood",
            "Ashes of the Stars",
            "Bottled Faith",
            "Brutal Restraint",
            "Crystallised Omniscience",
            "Dying Sun",
            "Unnatural Instinct",
            "Legacy of Fury",
            "Thread of Hope",
            "Impossible Escape",
        ];

        const stats = [
            rand(5, 50),
            rand(5, 50),
            rand(5, 50),
            rand(5, 50),
            rand(5, 50),
            rand(5, 50),
        ];

        const tx = await equipment.createEquipment(accounts[0], equipmentNames[amount % 12], stats);

        await tx.wait();

        const newIteration = amount - 1;

        if (newIteration > 0) {
            await createTestEquipment(equipment, newIteration);
        }
    }
}

/**
 * Returns a random number between min (inclusive) and max (exclusive)
 */
function getRandomArbitrary(min: number, max: number) {
    return Math.random() * (max - min) + min;
}

/**
 * Returns a random integer between min (inclusive) and max (inclusive).
 * The value is no lower than min (or the next integer greater than min
 * if min isn't an integer) and no greater than max (or the next integer
 * lower than max if max isn't an integer).
 * Using Math.round() will give you a non-uniform distribution!
 */
function rand(min: number, max: number) {
    min = Math.ceil(min);
    max = Math.floor(max);
    return Math.floor(Math.random() * (max - min + 1)) + min;
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
