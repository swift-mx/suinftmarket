import { MoveCallTransaction, ObjectContentFields } from '@mysten/sui.js';
import { CreateCollectionTXPayloadParams, ListingItemTxPayloadParams, AdjustPriceTxPayloadParams, DelistingItemTxPayloadParams, PurchaseItemTxPayloadParams, PurchaseMutilItemTxPayloadParams, CollectProfitCollectionTxPayloadParams, CollectProfitsTxPayloadParams, UpdateCollectionOwnerTxPayloadParams, UpdateCollectionFeeTxPayloadParams, UpdateCollectionInfoTxPayloadParams, UpdateMarketFeeTxPayloadParams } from './params';
import { SDK } from '../../sdk/sdk';
import { IModule } from '../../interfaces/IModule';
import { CollectionInfo } from '../../types';
export declare class MarketMoudle implements IModule {
    protected _sdk: SDK;
    get sdk(): SDK;
    constructor(sdk: SDK);
    getCollectionInfo(collectionId: string): Promise<CollectionInfo>;
    getItemInfo(itemId: string): Promise<ObjectContentFields>;
    getCollectionItemids(collectionId: string): Promise<string[]>;
    buildCreateCollectionTransaction(params: CreateCollectionTXPayloadParams): MoveCallTransaction;
    buildListingItemTransaction(params: ListingItemTxPayloadParams): MoveCallTransaction;
    buildAdjustPriceTransaction(params: AdjustPriceTxPayloadParams): MoveCallTransaction;
    buildDelistingItemTransaction(params: DelistingItemTxPayloadParams): MoveCallTransaction;
    buildPurchaseItemTransaction(params: PurchaseItemTxPayloadParams): MoveCallTransaction;
    buildPurchaseMutilItemTransaction(params: PurchaseMutilItemTxPayloadParams): MoveCallTransaction;
    buildCollecProfitCollection(params: CollectProfitCollectionTxPayloadParams): MoveCallTransaction;
    buildCollecProfitMarket(params: CollectProfitsTxPayloadParams): MoveCallTransaction;
    buildUpdateCollectionOwner(params: UpdateCollectionOwnerTxPayloadParams): MoveCallTransaction;
    buildUpdateCollectionfee(params: UpdateCollectionFeeTxPayloadParams): MoveCallTransaction;
    buildUpdateCollectionTwitter(params: UpdateCollectionInfoTxPayloadParams): MoveCallTransaction;
    buildUpdateCollectionWebsite(params: UpdateCollectionInfoTxPayloadParams): MoveCallTransaction;
    buildUpdateCollectionDiscord(params: UpdateCollectionInfoTxPayloadParams): MoveCallTransaction;
    buildMarketFee(params: UpdateMarketFeeTxPayloadParams): MoveCallTransaction;
}
//# sourceMappingURL=MarketMoudle.d.ts.map