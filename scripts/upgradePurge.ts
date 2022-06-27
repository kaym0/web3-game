import { run, ethers } from "hardhat";
import "@nomiclabs/hardhat-ethers";
// @ts-ignore
import { getSelectors, FacetCutAction, removeSelectors } from "./libraries/diamond.js";
import { any } from "hardhat/internal/core/params/argumentTypes";

const FacetNames = ["CharacterFacet"];
const FacetAddresses = ["0xc8024fb9A97553A39Cf6302507221C22f95ac94B"];
const diamondAddress = "0x9f9D6Fdfb1Da8ABD6F363Aa1fED939944Bd71F5c";

async function deploy() {
    const diamond = await getContractInstance(
        "CharacterDiamond",
        "0x06223aEA47F97694Fda88D9FDB98646943ba70C2"
    );

    const diamondCutFacet = await ethers.getContractAt("DiamondCutFacet", diamondAddress);
    const diamondLoupeFacet = await ethers.getContractAt("DiamondLoupeFacet", diamondAddress);

    //const selectors = await getSelectors(diamondAddress);


    await removeAllFunctions();



    async function removeAllFunctions() {
        let selectors = [];
        let facets = await diamondLoupeFacet.facets();
        for (let i = 0; i < facets.length; i++) {
            selectors.push(...facets[i].functionSelectors);
        }

        console.log("selectorsA", selectors)
        selectors = removeSelectors(selectors, [
            "facets()",
            "diamondCut(tuple(address,uint8,bytes4[])[],address,bytes)",
            "facetFunctionSelectors(address _facet)",
            "facetAddress(bytes4 _functionSelector)",
            "facetAddresses()",
            "supportsInterface(bytes4 _interfaceId)"
        ]);
        console.log("selectorsB", selectors)
        let tx = await diamondCutFacet.diamondCut(
            [
                {
                    facetAddress: ethers.constants.AddressZero,
                    action: FacetCutAction.Remove,
                    functionSelectors: selectors,
                },
            ],
            ethers.constants.AddressZero,
            "0x",
            { gasLimit: 800000 }
        );
        let receipt = await tx.wait();
        if (!receipt.status) {
            throw Error(`Diamond upgrade failed: ${tx.hash}`);
        }
        const currentFacets = await diamondLoupeFacet.facets();

        console.log(currentFacets);
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
