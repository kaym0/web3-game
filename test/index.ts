import { expect } from "chai";
import { Contract } from "ethers";
import { ethers } from "hardhat";
import { toWei } from "./functions";

describe("Token", function () {
    let accounts: any;
    let equipment: any;
    let characters: any;

    before(async () => {
        const signers = await ethers.getSigners();
        const Equipment = await ethers.getContractFactory("DreamEquipment");
        const Characters = await ethers.getContractFactory("Characters");

        equipment = await Equipment.deploy();
        await equipment.deployed();
        characters = await Characters.deploy();
        await characters.deployed();

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
            await characters.mintCharacter({
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
            const answers = await characters.testBitwise()

            console.log(answers);
        })
    })
});
