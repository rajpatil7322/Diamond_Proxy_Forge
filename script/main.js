const {ethers}=require("ethers");
const hre = require("hardhat");
const DiamondData=require("../artifacts/src/Diamond.sol/Diamond.json");
const FacetAData=require("../artifacts/src/facet/FacetA.sol/FacetA.json");
const FacetBData=require("../artifacts/src/facet/FacetB.sol/FacetB.json");

async function main(){
    const provider=new ethers.providers.JsonRpcProvider("http://127.0.0.1:8545");

    const user1=await(provider.getSigner(0)).getAddress();
    const user2=await(provider.getSigner(1)).getAddress();
    const user3=await(provider.getSigner(2)).getAddress();
    const user4=await(provider.getSigner(3)).getAddress();
    const user5=await(provider.getSigner(4)).getAddress();

    const Diamondfactory= new ethers.ContractFactory(DiamondData.abi,DiamondData.bytecode,provider.getSigner(0));

    const FacetAFactory=new ethers.ContractFactory(FacetAData.abi,FacetAData.bytecode,provider.getSigner(0));

    const FacetBFactory=new ethers.ContractFactory(FacetBData.abi,FacetBData.bytecode,provider.getSigner(0));
    
    const diamond=await Diamondfactory.deploy(user1);
    console.log("Diamond deployed At",diamond.address);
    console.log("Owner of diamond",await diamond.getOwner());

    const facetA=await FacetAFactory.deploy();
    console.log("FacetA deployed At",facetA.address);

    const facetB=await FacetBFactory.deploy();
    console.log("FacetB deployed At",facetB.address);
    

    const diamonCutA=await diamond.connect(provider.getSigner(0)).diamondCut({
        facetAddress:facetA.address,
        functionSelectors:[ethers.utils.id('add(uint256)').substring(0, 10),ethers.utils.id('getNum()').substring(0, 10)]
    })
    await diamonCutA.wait();

    const proxyA=new ethers.Contract(diamond.address,FacetAData.abi,provider);
    
    const tx=await proxyA.connect(provider.getSigner(0)).add(10);
    await tx.wait();

    const addFunction=await diamond.connect(provider.getSigner(0)).addFunctions(facetA.address,[ethers.utils.id('multiply(uint256)').substring(0,10)]);
    await addFunction.wait();

    const multiplyTx=await proxyA.connect(provider.getSigner(0)).multiply(5);
    await multiplyTx.wait();

    const removeTX=await diamond.connect(provider.getSigner(0)).removeFunctions(ethers.constants.AddressZero,[ethers.utils.id('add(uint256)').substring(0, 10)]);
    await removeTX.wait();
    console.log("remove tx successfull!!!")
 
    console.log(Number(await proxyA.getNum()));


    const diamonCutB=await diamond.connect(provider.getSigner(0)).diamondCut({
        facetAddress:facetB.address,
        functionSelectors:[
            ethers.utils.id('sub(uint256)').substring(0, 10),
            ethers.utils.id('getNum(uint256)').substring(0, 10),
            ethers.utils.id('addData(string)').substring(0, 10),
            ethers.utils.id('getData()').substring(0, 10)]
        })
    await diamonCutB.wait();

    const proxyB=new ethers.Contract(diamond.address,FacetBData.abi,provider);

    const tx1=await proxyB.connect(provider.getSigner(0)).sub(5);
    await tx1.wait();

    console.log(Number(await proxyB.getNum()));



}

main();