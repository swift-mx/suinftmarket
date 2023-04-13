## Market-Sui-SDK


## Init SDK
```ts
import { SDK,TESTNET_CONFIG } from 'market-sui-sdk';
(async function main() {
    const sdk = new SDK(TESTNET_CONFIG);
})();
```
## Query Collection
```ts
collectionID='0xb271d4d214de1a8c5a665505dfec98a2c490d80e'
import {  SDK,DEVNET_CONFIG } from "market-sui-sdk";
async function main() {
    
    const sdk = new SDK(DEVNET_CONFIG);
    const details= await sdk.Market.getCollectionInfo('0xb271d4d214de1a8c5a665505dfec98a2c490d80e')
    console.log(details)
};
```
## Query Item
```ts
itemID='0x7ba9d57d0ca150aeca6864f58b00e6773234d75e'
import { SDK,DEVNET_CONFIG } from "market-sui-sdk";

async function main() {
    
    const sdk = new SDK(DEVNET_CONFIG);

    const details= await sdk.Market.getItemInfo('0x7ba9d57d0ca150aeca6864f58b00e6773234d75e')
    console.log(details)

};
```

## CreateCollection
```ts

import { SDK,DEVNET_CONFIG,CreateCollectionTXPayloadParams } from "market-sui-sdk";
import { Ed25519Keypair, RawSigner } from '@mysten/sui.js';

async function main() {
    
    const sdk = new SDK(DEVNET_CONFIG);
    const keypair = new Ed25519Keypair();
    const signer = new RawSigner(keypair,sdk.jsonRpcProvider);


    const create_collection_param:CreateCollectionTXPayloadParams={
        market: DEVNET_CONFIG.marketObjectId,
        name: 'collection_name',
        description: 'collection_description',
        tags: ['tags'],
        logo_image: 'logo_image',
        featured_image: 'featured_image',
        website: 'website',
        twitter: 'twitter',
        discord: 'discord',
        fee: 1,
        itemType: '0x2::devnet_nft::DevNetNFT',
        //用于支付gas
        gasPaymentObjectId: '0xd6b6961ea31d0a11ea631b14cc96ad53ad923c0e'
    }

    const moveExec= await sdk.Market.buildCreateCollectionTransaction(create_collection_param);
    const Txs=await signer.executeMoveCall(moveExec)

    console.log(Txs)

};
```
## List ITem
```ts
import { SDK,DEVNET_CONFIG,ListingItemTxPayloadParams } from "market-sui-sdk";
import { Ed25519Keypair, RawSigner } from '@mysten/sui.js';

async function main() {
    
    const sdk = new SDK(DEVNET_CONFIG);
    const keypair = new Ed25519Keypair();
    const signer = new RawSigner(keypair,sdk.jsonRpcProvider);

    const list_item_param:ListingItemTxPayloadParams={
        collectionId: '0x...',
        itemId: '0x...',
        price: 100,
        itemType: '0x2::devnet_nft::DevNetNFT',
        gasPaymentObjectId: '0xd6b6961ea31d0a11ea631b14cc96ad53ad923c0e',
    }

    const moveExec= await sdk.Market.buildListingItemTransaction(list_item_param);
    const Txs=await signer.executeMoveCall(moveExec)
    console.log(Txs)

};

```
## Delist Item
```ts
....
```

