import { ethers } from "hardhat";
import { toWei } from "./functions";

describe("Token", function () {
    let accounts: any;
    let equipment: any;
    let gems: any;
    let market: any;
    let ore: any;
    let fish: any;
    let wood: any;
    let stone: any;

    before(async () => {
        const signers = await ethers.getSigners();

        equipment = await deployContract("Equipment");
        gems = await deployContract("Gems");
        market = await deployContract("Marketplace", [equipment.address, gems.address]);
        ore = await deployContract("Ore");
        fish = await deployContract("Fish");
        wood = await deployContract("Wood");
        stone = await deployContract("Stone");

        accounts = signers.map((account) => account.address);
    });

    describe("Pre-approve all materials for marketplace", async () => {
        it("scucessfully approves all", async () => {
            await ore.approve(
                market.address,
                toWei("939849028490234239042309324290239423432432432423")
            );
            await fish.approve(
                market.address,
                toWei("939849028490234239042309324290239423432432432423")
            );
            await wood.approve(
                market.address,
                toWei("939849028490234239042309324290239423432432432423")
            );
            await stone.approve(
                market.address,
                toWei("939849028490234239042309324290239423432432432423")
            );
        });
    });

    describe("Mints test funds from each material contract", async () => {
        it("Successfully mints to owner", async () => {
            await ore.mintTo(accounts[0], toWei("100000000000"));
            await fish.mintTo(accounts[0], toWei("100000000000"));
            await wood.mintTo(accounts[0], toWei("100000000000"));
            await stone.mintTo(accounts[0], toWei("100000000000"));
        });
    });

    describe("Add materialIds", async () => {
        it("Successfully adds materialIds", async () => {
            await market.addMaterialId("0", ore.address);
            await market.addMaterialId("1", fish.address);
            await market.addMaterialId("2", wood.address);
            await market.addMaterialId("3", stone.address);
        });
    });

    describe("Add ore listing", async () => {
        it("Checks ore listing", async () => {
            await market.addMaterialListing("0", toWei("1"), toWei("10000"));
            await market.addMaterialListing("0", toWei("1"), toWei("3289"));
            await market.addMaterialListing("0", toWei("1"), toWei("584395"));
            await market.addMaterialListing("0", toWei("1"), toWei("123112"));
            await market.addMaterialListing("0", toWei("1"), toWei("64334"));
            await market.addMaterialListing("0", toWei("1"), toWei("34232"));
            await market.addMaterialListing("0", toWei("1"), toWei("7472323"));
            await market.addMaterialListing("0", toWei("1"), toWei("9324"));
            await market.addMaterialListing("0", toWei("1"), toWei("9560"));
        });
    });

    describe("Fetches listing", async () => {
        it("Successfully fetches listing", async () => {
            const listings = await market.allMaterialListings("0");

            //console.log(listings);
        });
    });

    describe("materialListingFromRange", async () => {
        it("Successfully gets material ling from range", async () => {
            const listings =await  market.materialListingFromRange("0", "1", "5")

            console.log(listings);
        })
    })

    async function deployContract(factoryName: string, args: any[] = []) {
        const Factory = await ethers.getContractFactory(factoryName);

        const contract = await Factory.deploy(...args);

        await contract.deployed();

        return contract;
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
