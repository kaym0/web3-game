import { run, ethers } from "hardhat";
import "@nomiclabs/hardhat-ethers";
// @ts-ignore
import { getSelectors, FacetCutAction } from "./libraries/diamond.js";
import { any } from "hardhat/internal/core/params/argumentTypes";

const FacetNames = ["CharacterFacet"];
const FacetAddresses = ["0x9f9D6Fdfb1Da8ABD6F363Aa1fED939944Bd71F5c"];
async function deploy() {
    const diamond = await getContractInstance(
        "CharacterDiamond",
        "0x9f9D6Fdfb1Da8ABD6F363Aa1fED939944Bd71F5c"
    );

    await removeFacets(FacetNames);
    async function removeFacets(FacetNames: string[]) {
        console.log("Removing selectors");
        const cut = [];

        for (const FacetName of FacetNames) {
            const Facet = await ethers.getContractFactory(FacetName);
            const facet = Facet.attach("0x70B5840b21D1ca8C998b3Ad6D5e5D8C7933C86Bf");
            cut.push({
                facetAddress: ethers.constants.AddressZero,
                action: FacetCutAction.Remove,
                functionSelectors: getSelectors(facet),
            });
        }

        const diamondCut = await ethers.getContractAt("IDiamondCut", diamond.address);
        //const DiamondInit  = await ethers.getContractFactory("DiamondInit");
        //const diamondInit = await DiamondInit.deploy();
        //await diamondInit.deployed();

        let tx;
        let receipt;

        console.log(cut);

        tx = await diamondCut.diamondCut(cut, ethers.constants.AddressZero, "0x");
        console.log("Diamond cut tx:             ", tx.hash);
        receipt = await tx.wait();

        if (!receipt.status) {
            throw Error(`Diamond upgrade failed: ${tx.hash}`);
        }
    }

    async function getContractInstance(factoryName: string, address: string) {
        const Factory = await ethers.getContractFactory(factoryName);
        return Factory.attach(address);
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
