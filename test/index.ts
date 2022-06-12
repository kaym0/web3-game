import { ethers } from "hardhat";
import { addOperator, advanceTimeAndBlock, toWei } from "./functions";

describe("Token", function () {
    let accounts: any;
    let equipment: any;
    let characters: any;
    let coin: any;
    let market: any;
    let area: any;

    before(async () => {
        const signers = await ethers.getSigners();
        const Equipment = await ethers.getContractFactory("Equipment");
        const Characters = await ethers.getContractFactory("Characters");
        const Market = await ethers.getContractFactory("Marketplace");
        const Coin = await ethers.getContractFactory("Gems");
        const Area = await ethers.getContractFactory("Area");

        equipment = await Equipment.deploy();
        await equipment.deployed();
        characters = await Characters.deploy();
        await characters.deployed();
        coin = await Coin.deploy();
        await coin.deployed();
        market = await Market.deploy(equipment.address, coin.address);
        await market.deployed();
        area = await Area.deploy(characters.address, coin.address, "500");
        await area.deployed();

        await addOperator(equipment, characters.address);
        await addOperator(characters, equipment.address);
        await addOperator(coin, area.address);
        await addOperator(characters, area.address);

        accounts = signers.map((account) => account.address);
    });

    describe("Init", async () => {
        it("Initializes character", async () => {
            await characters.initialize(equipment.address);
        });
    });

    describe("mintCharacter", async () => {
        it("deploys", async () => {
            const random = ethers.utils.randomBytes(5);
            await characters.mintCharacter("name", {
                value: toWei("0.0001"),
            });
        });
    });

    describe("getCharactersOfOwner", async () => {
        it("Gets owners characters", async () => {
            const c = await characters.getCharactersOfOwner(accounts[0]);

            console.log(c);
        });
    });

    describe("getCharacters", async () => {
        it("Gets a singular character", async () => {
            const c = await characters.getCharacter(0);
            console.log(c);
        });
    });

    describe("gainExperience", async () => {
        it("Gains experience fro character", async () => {
            await characters.gainExperience(0, "200");

            const c = await characters.getCharacter(0);

            console.log(c);
        });
    });

    describe("testBitwise", async () => {
        it("ya motha", async () => {
            const answers = await characters.testBitwise();

            console.log(answers);
        });
    });

    describe("seeds", async () => {
        it("fetches character seeds", async () => {
            const seeds = await characters.seeds(0);
            console.log(seeds);
        });
    });

    describe("Simulate leveling up", async () => {
        it("Simulates leveling up several times, then retreives stat values", async () => {
            await characters.gainExperience(0, "200");
            await characters.gainExperience(0, "200");
            await characters.gainExperience(0, "200");
            await characters.gainExperience(0, "200");
            await characters.gainExperience(0, "200");
            await characters.gainExperience(0, "200");
            await characters.gainExperience(0, "200");

            const character = await characters.getCharacter(0);

            console.log(character);
        });
    });

    describe("createEquipment", async () => {
        it("Creates several fake equipments to test with", async () => {
            await createTestEquipment(equipment, 10);
        });
    });

    describe("Adds to market", async () => {
        it("ASDAS", async () => {
            await equipment.setApprovalForAll(market.address, true);

            await market.listItem("0", "100000000000000");
        });
    });

    describe("Fetch market listings", async () => {
        it("Gets market listings", async () => {
            const listings = await market.getListings();
            console.log(listings);
        });
    });

    describe("Enters area", async () => {
        it("Enters area", async () => {
            await characters.setApprovalForAll(area.address, true);

            const character = await characters.ownerOf("0");
            await area.enter("0");

            await advanceTimeAndBlock(86400, ethers);
        });
    });

    describe("Checks expRate", async () => {
        it("Checks rate of the rewards", async () => {
            const expRate = await area.getExpPerHour("0");

            console.log(expRate);
        });
    });

    describe("Checks successRate", async () => {
        it("Checks rate of the rewards", async () => {
            const successRate = await area.getSuccessRate("0");

            console.log(successRate);
        });
    });

    describe("Checks dropRate", async () => {
        it("Checks rate of the rewards", async () => {
            const expRate = await area.getDropRatePerHour("0");

            console.log(expRate);
        });
    });

    describe("TestAreaSuccess", async () => {
        it("Checks rate of the rewards", async () => {
            const expRate = await area.testAreaSuccess("0");

            console.log(expRate);
        });
    });

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

        await equipment.createEquipment(accounts[0], equipmentNames[amount % 12], stats);

        const newIteration = amount - 1;

        if (newIteration > 0) {
            await createTestEquipment(equipment, newIteration);
        }
    }
});

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
