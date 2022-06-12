import { ethers } from "hardhat";

async function main() {
    const characterContract = "0x5bD5D7a6A6db85696027622e4126808809Bf7228"
    const gemsContract = "0x6Eaeff51D913c0b1814cDD31B6288218e7d7B9Ba"

    const Area = await ethers.getContractFactory("AreaFactory");

    const signers = await ethers.getSigners();
    const accounts = signers.map(((account) => account.address ));
    const area: any = await Area.deploy(characterContract, gemsContract);
    // Await deployment.
    await area.deployed();
    const tx = await area.createArea("1", "500", "50", "1", "20");
    const response = await tx.wait();
    console.log(response);
    console.log(tx);


    console.log("AreaFactory deployed to:      ", area.address)
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});