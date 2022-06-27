import { ethers } from "hardhat";

async function main() {
    const Area = await ethers.getContractFactory("Area");
    const Character = await ethers.getContractFactory("CharacterFacet");


    const signers = await ethers.getSigners();
    const accounts = signers.map(((account) => account.address ));


    const characters: any = Character.attach("0xB0A4394705E2ED0Ed2ef68fC9a5C5c95427C9888")
    const area: any = Area.attach("0x4E508A3fA34A77A21d3e00119A7BD286Ff753757");



    const approve = await characters.setApprovalForAll(area.address, true);

    const ares = await approve.wait();


    console.log(ares);


    const tx = await area.enter("0");

    const response = await tx.wait();

    
    console.log(response);


    console.log(tx);

    //console.log("Equipment deployed to:", equipment.address);
    //console.log("Characters deployed to:", characters.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});