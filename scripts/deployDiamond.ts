import { run, ethers } from "hardhat";
import "@nomiclabs/hardhat-ethers";
// @ts-ignore
import { getSelectors, FacetCutAction } from "./libraries/diamond.js";
import { any } from "hardhat/internal/core/params/argumentTypes";

const FacetNames = ["DiamondLoupeFacet", "CharacterFacet", "OperatorFacet", "CharacterUpdateFacet"];

async function deploy() {
    await run("compile");
    const [...signers] = await ethers.getSigners();
    const accounts = signers.map((account) => account.address);

    ////////////////////////////////////////////////////////////////////////
    ///////////////////////Deploy DiamondCutFacet///////////////////////////
    ////////////////////////////////////////////////////////////////////////
    const diamondCutFacet = await deployContract("DiamondCutFacet");

    ////////////////////////////////////////////////////////////////////////
    ///////////////////////// Deploy Diamond ///////////////////////////////
    ////////////////////////////////////////////////////////////////////////
    const diamond = await deployContract("CharacterDiamond", [
        accounts[0],
        diamondCutFacet.address,
    ]);

    ////////////////////////////////////////////////////////////////////////
    ////////////////////// Deploy DiamondInit ///////////////////////////////
    ////////////////////////////////////////////////////////////////////////
    const diamondInit = await deployContract("DiamondInit");

    ////////////////////////////////////////////////////////////////////////
    ///////////////////// Deploy All Facets ////////////////////////////////
    ////////////////////////////////////////////////////////////////////////
    await deployFacets(FacetNames);

    ////////////////////////////////////////////////////////////////////////
    ///////////////////// Get Character Instance ///////////////////////////
    ////////////////////////////////////////////////////////////////////////
    const characters = await contractInstance("CharacterFacet", diamond.address);

    ////////////////////////////////////////////////////////////////////////
    ///////////////////// Deploy Equipment Contract ////////////////////////
    ////////////////////////////////////////////////////////////////////////
    const equipment = await deployContract("Equipment");

    await initializeCharacterContract(characters, [equipment.address]);

    const gems = await deployContract("Gems");

    const market = await deployContract("Marketplace", [equipment.address, gems.address]);

    console.log("Completed diamond cut");
    console.log("");
    console.log("");
    console.log("CharacterDiamond deployed to:          ", diamond.address);
    console.log("DiamondCutFacet deployed to:           ", diamondCutFacet.address);
    console.log("DiamondInit deployed:                  ", diamondInit.address);
    console.log("")
    console.log(`export const equipmentContract = "${equipment.address}"`);
    console.log(`export const characterContract = "${characters.address}"`);
    console.log(`export const gemsContract = "${gems.address}"`);
    console.log(`export const marketContract = "${market.address}"`);


    //await addOperator(equipment, characters.address);
    //await addOperator(characters, equipment.address);
    //await addOperator(gems, area.address);
    //await addOperator(characters, area.address);


    async function addOperator(contract: any, operator: any) {
        const tx = await contract.addOperator(operator);
        await tx.wait();
    }


    async function initializeCharacterContract(contract: any, args: string[]) {
        const tx = await contract.initialize(...args);
        await tx.wait();
        return;
    }

    async function contractInstance(factoryName: string, contractAddress: string) {
        const Factory = await ethers.getContractFactory(factoryName);
        const contract = Factory.attach(contractAddress);
        return contract;
    }

    async function deployContract(contractName: string, args: any[] = []) {
        const Factory = await ethers.getContractFactory(contractName);
        const contract = await Factory.deploy(...args);
        await contract.deployed();

        return contract;
    }

    async function deployFacets(FacetNames: string[]) {
        console.log("Deploying facets");
        const cut = [];

        for (const FacetName of FacetNames) {
            const Facet = await ethers.getContractFactory(FacetName);
            const facet = await Facet.deploy();
            await facet.deployed();
            console.log(`${FacetName} deployed: ${facet.address}`);
            cut.push({
                facetAddress: facet.address,
                action: FacetCutAction.Add,
                functionSelectors: getSelectors(facet),
            });
        }

        const diamondCut = await ethers.getContractAt("IDiamondCut", diamond.address);
        let tx;
        let receipt;
        // call to init function
        let functionCall = diamondInit.interface.encodeFunctionData("init");
        tx = await diamondCut.diamondCut(cut, diamondInit.address, functionCall);
        console.log("Diamond cut tx:             ", tx.hash);
        receipt = await tx.wait();

        if (!receipt.status) {
            throw Error(`Diamond upgrade failed: ${tx.hash}`);
        }
    }

    async function mint(contract: any, name: string) {
        const tx = await contract.mintCharacter(name);
        await tx.wait();
    }

    async function getCharacter(contract: any, characterID: string) {
        const char = await contract.getCharacter(characterID);
        return char;
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
