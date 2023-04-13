import { SDK } from "../src";
import { DEVNET_CONFIG } from "../src/config/configuration";

async function main() {
    const sdk = new SDK(DEVNET_CONFIG);
    const details= await sdk.Market.getCollectionInfo('0x4c1d0903e52cc23fea8747c0af53590215ba0ea7')
    console.log(details)

};

main().catch((error)=>{
    console.log(error)
})




