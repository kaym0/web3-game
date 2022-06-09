import { BigNumber, Contract, ContractFactory, ethers } from "ethers";
import { MerkleTree } from "merkletreejs";
import keccak256 from "keccak256";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";

const abi = ethers.utils.defaultAbiCoder;

export async function addOperator(contract: any, operator: any) {
    const tx = await contract.addOperator(operator);
    await tx.wait();
}

export const generateTestList = (accounts: any) => {
    accounts.pop(0);
    const list: any[] = [];
    accounts.forEach((account: string) => {
        list.push({
            account: account,
            startAmount: ethers.utils.parseUnits("100", "18").toString(),
        });
    });

    return list;
};

export const getMerkleRoot = (testList: any) => {
    try {
        const leafNodes = testList.map((item: any) =>
            ethers.utils.hexStripZeros(
                abi.encode(["address", "uint256"], [item.account, item.startAmount])
            )
        );
        const merkleTree = new MerkleTree(leafNodes, keccak256, {
            hashLeaves: true,
            sortPairs: true,
        });
        const root = merkleTree.getHexRoot();
        return {
            root,
        };
    } catch (error) {
        console.log("Account does not exist");
    }
};

export const getMerkleData = (account: any, startAmount: any, testList: any) => {
    try {
        const accountData = testList.find((o: any) => o.account == account);
        const leafNodes = testList.map((item: any) =>
            ethers.utils.hexStripZeros(
                abi.encode(["address", "uint256"], [item.account, item.startAmount])
            )
        );
        const merkleTree = new MerkleTree(leafNodes, keccak256, {
            hashLeaves: true,
            sortPairs: true,
        });
        const root = merkleTree.getHexRoot();
        const leaf = keccak256(
            ethers.utils.hexStripZeros(abi.encode(["address", "uint256"], [account, startAmount]))
        );
        const proof = merkleTree.getHexProof(leaf);

        return {
            root,
            leaf,
            proof,
        };
    } catch (error) {
        console.log("Account does not exist");
    }
};

export const advanceTime = (time: any, ethers: any) => {
    return new Promise(async (resolve: any, reject: any) => {
        await ethers.provider.send("evm_increaseTime", [time]);
        resolve();
    });
};

export const advanceTimeAndBlock = async (time: number, ethers: any) => {
    await advanceTime(time, ethers);
    await advanceBlock(ethers);
};

export const advanceBlock = (ethers: any) => {
    return new Promise(async (resolve: any, reject: any) => {
        await ethers.provider.send("evm_mine");
        resolve();
    });
};

export const toWei = (amount: string | number | BigNumber): string => {
    return ethers.utils.parseUnits(amount.toString(), "18").toString();
};

export const fromWei = (amount: string | number | BigNumber): string => {
    return ethers.utils.formatUnits(amount, "18");
};

export async function deployContract(
    factory: ContractFactory,
    args: (string | number)[] = []
): Promise<Contract> {
    const contract = await factory.deploy(...args);
    await contract.deployed();

    return contract;
}

interface ContractData {
    factory: ContractFactory;
    args: (string | number)[];
}

export async function deployContracts(
    data: ContractData[],
    contracts: Contract[] = []
): Promise<Contract[] | void> {
    const instance = (data as ContractData[]).shift();

    if (instance === undefined) return;

    const { factory, args } = instance;

    const contract = await factory.deploy(...args);

    await contract.deployed();

    if (data.length) {
        await deployContracts(data, [...contracts, contract]);
    } else {
        return [...contracts, contract];
    }
}
