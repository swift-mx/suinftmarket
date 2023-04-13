import {  getObjectFields, MoveCallTransaction, ObjectContentFields,SuiEventFilter } from '@mysten/sui.js';
import {CreateCollectionTXPayloadParams,
        ListingItemTxPayloadParams,
        AdjustPriceTxPayloadParams,
        DelistingItemTxPayloadParams,
        PurchaseItemTxPayloadParams,
        PurchaseMutilItemTxPayloadParams,
        CollectProfitCollectionTxPayloadParams,
        CollectProfitsTxPayloadParams,
        UpdateCollectionOwnerTxPayloadParams,
        UpdateCollectionFeeTxPayloadParams,
        UpdateCollectionInfoTxPayloadParams,
        UpdateMarketFeeTxPayloadParams,
        } from './params'

import { SDK } from '../../sdk/sdk';

import { IModule } from '../../interfaces/IModule'
import { CollectionInfo } from '../../types';



export class MarketMoudle implements IModule {
    protected _sdk: SDK;

      get sdk() {
        return this._sdk;
      }
      
      constructor(sdk: SDK) {
        this._sdk = sdk;
      }

      async getCollectionInfo(collectionId: string):Promise<CollectionInfo>{

        const collectionObject=await this._sdk.jsonRpcProvider.getObject(collectionId);
        const details= getObjectFields(collectionObject);
        
        if (details==undefined){
            return Promise.reject("Invaild collectionId")
        }
    
        const info: CollectionInfo={
            collectionId,
            name: details?.["name"],
            description: details?.["description"],
            tags:  details?.["tags"],
            logo_image: details?.["tags"],
            featured_image: details?.["tags"],
            website: details?.["website"],
            twitter: details?.["twitter"],
            discord: details?.["discord"],
            receiver: details?.["receiver"],
            balance: details?.["balance"],
            fee: details?.["fee"]
        }
        return Promise.resolve(info)
      }

      async getItemInfo(itemId: string):Promise<ObjectContentFields>{
        const itemObject=await this._sdk.jsonRpcProvider.getObject(itemId);
        let info= getObjectFields(itemObject)!
        return Promise.resolve(info)
      }


      async getCollectionItemids(collectionId: string):Promise<string[]>{
        const subObject=await this._sdk.jsonRpcProvider.getDynamicFields(collectionId);
        let  itemIds=new Array<string>(0);

        for (let i=0;i<subObject.data.length;i++){

            const itemId=await this._sdk.jsonRpcProvider.getDynamicFields(subObject.data[i].objectId).then((result)=>{
                return result.data[0].objectId
            });
            itemIds.push(itemId)
        }       
        return Promise.resolve(itemIds)
      }

       buildCreateCollectionTransaction(params: CreateCollectionTXPayloadParams):MoveCallTransaction{
            const { packageObjectId } = this.sdk.networkOptions;

            const txn:MoveCallTransaction = {
                packageObjectId:packageObjectId,
                module: 'market',
                function: 'create_collection',
                arguments: [params.market,params.name,params.description,params.tags,params.logo_image,params.featured_image,params.website,params.twitter,params.discord],
                typeArguments: [params.itemType],
                gasPayment: params.gasPaymentObjectId,
                gasBudget: 10000,
            }  
            return txn
      }
      buildListingItemTransaction(params: ListingItemTxPayloadParams):MoveCallTransaction{
        const { packageObjectId } = this.sdk.networkOptions;

        const txn:MoveCallTransaction = {
            packageObjectId:packageObjectId,
            module: 'market',
            function: 'list',
            arguments: [params.collectionId,params.itemId,params.price],
            typeArguments: [params.itemType],
            gasPayment: params.gasPaymentObjectId,
            gasBudget: 10000,
        }  
        return txn
      }
      buildAdjustPriceTransaction(params:AdjustPriceTxPayloadParams):MoveCallTransaction{
        const { packageObjectId } = this.sdk.networkOptions;
        const txn:MoveCallTransaction = {
            packageObjectId:packageObjectId,
            module: 'market',
            function: 'adjust_price',
            arguments: [params.collectionId,params.itemId,params.price],
            typeArguments: [params.itemType],
            gasPayment: params.gasPaymentObjectId,
            gasBudget: 10000,
        }  
        return txn
      }
      buildDelistingItemTransaction(params:DelistingItemTxPayloadParams):MoveCallTransaction{
        const { packageObjectId } = this.sdk.networkOptions;
        const txn:MoveCallTransaction = {
            packageObjectId:packageObjectId,
            module: 'market',
            function: 'delist_take',
            arguments: [params.collectionId,params.itemId],
            typeArguments: [params.itemType],
            gasPayment: params.gasPaymentObjectId,
            gasBudget: 10000,
        }  
        return txn
        
      }
      buildPurchaseItemTransaction(params: PurchaseItemTxPayloadParams):MoveCallTransaction{
        const { packageObjectId } = this.sdk.networkOptions;
        const txn:MoveCallTransaction = {
            packageObjectId:packageObjectId,
            module: 'market',
            function: 'buy_and_take_script',
            arguments: [params.marketId,params.collectionId,params.itemId,params.paidCoin,params.receiver],
            typeArguments: [params.itemType],
            gasPayment: params.gasPaymentObjectId,
            gasBudget: 10000,
        }  
        return txn
      }
      buildPurchaseMutilItemTransaction(params: PurchaseMutilItemTxPayloadParams):MoveCallTransaction{
        const { packageObjectId } = this.sdk.networkOptions;
        const txn:MoveCallTransaction = {
            packageObjectId:packageObjectId,
            module: 'market',
            function: 'buy_muti_item_script',
            arguments: [params.marketId,params.collectionId,params.itemIds,params.paidCoins,params.receiver],
            typeArguments: [params.itemType],
            gasPayment: params.gasPaymentObjectId,
            gasBudget: 10000,
        }  
        return txn
      }
      buildCollecProfitCollection(params:CollectProfitCollectionTxPayloadParams):MoveCallTransaction{
        const { packageObjectId } = this.sdk.networkOptions;
        const txn:MoveCallTransaction = {
            packageObjectId:packageObjectId,
            module: 'market',
            function: 'collect_profit_collection',
            arguments: [params.collectionId,params.receiver],
            typeArguments: [params.itemType],
            gasPayment: params.gasPaymentObjectId,
            gasBudget: 10000,
        }  
        return txn
      }
      buildCollecProfitMarket(params:CollectProfitsTxPayloadParams):MoveCallTransaction{
        const { packageObjectId } = this.sdk.networkOptions;
        const txn:MoveCallTransaction = {
            packageObjectId:packageObjectId,
            module: 'market',
            function: 'collect_profits',
            arguments: [params.ownerObject,params.marketId,params.receiver],
            typeArguments: [params.itemType],
            gasPayment: params.gasPaymentObjectId,
            gasBudget: 10000,
        }  
        return txn
      }
      buildUpdateCollectionOwner(params: UpdateCollectionOwnerTxPayloadParams): MoveCallTransaction{
        const { packageObjectId } = this.sdk.networkOptions;
        const txn:MoveCallTransaction = {
            packageObjectId:packageObjectId,
            module: 'market',
            function: 'update_collection_owner',
            arguments: [params.collectionId,params.owner],
            typeArguments: [params.itemType],
            gasPayment: params.gasPaymentObjectId,
            gasBudget: 10000,
        }  
        return txn
      }
      buildUpdateCollectionfee(params: UpdateCollectionFeeTxPayloadParams): MoveCallTransaction{
        const { packageObjectId } = this.sdk.networkOptions;
        const txn:MoveCallTransaction = {
            packageObjectId:packageObjectId,
            module: 'market',
            function: 'update_collection_fee',
            arguments: [params.collectionId,params.fee],
            typeArguments: [params.itemType],
            gasPayment: params.gasPaymentObjectId,
            gasBudget: 10000,
        }  
        return txn
      }

      buildUpdateCollectionTwitter(params: UpdateCollectionInfoTxPayloadParams): MoveCallTransaction{
        const { packageObjectId } = this.sdk.networkOptions;
        const txn:MoveCallTransaction = {
            packageObjectId:packageObjectId,
            module: 'market',
            function: 'update_collection_twitter',
            arguments: [params.collectionId,params.social],
            typeArguments: [params.itemType],
            gasPayment: params.gasPaymentObjectId,
            gasBudget: 10000,
        }  
        return txn
      }
      buildUpdateCollectionWebsite(params: UpdateCollectionInfoTxPayloadParams): MoveCallTransaction{
        const { packageObjectId } = this.sdk.networkOptions;
        const txn:MoveCallTransaction = {
            packageObjectId:packageObjectId,
            module: 'market',
            function: 'update_collection_website',
            arguments: [params.collectionId,params.social],
            typeArguments: [params.itemType],
            gasPayment: params.gasPaymentObjectId,
            gasBudget: 10000,
        }  
        return txn
      }
      buildUpdateCollectionDiscord(params: UpdateCollectionInfoTxPayloadParams): MoveCallTransaction{
        const { packageObjectId } = this.sdk.networkOptions;
        const txn:MoveCallTransaction = {
            packageObjectId:packageObjectId,
            module: 'market',
            function: 'update_collection_discord',
            arguments: [params.collectionId,params.social],
            typeArguments: [params.itemType],
            gasPayment: params.gasPaymentObjectId,
            gasBudget: 10000,
        }  
        return txn
      }
      buildMarketFee(params: UpdateMarketFeeTxPayloadParams): MoveCallTransaction{
        const { packageObjectId } = this.sdk.networkOptions;
        const txn:MoveCallTransaction = {
            packageObjectId:packageObjectId,
            module: 'market',
            function: 'update_market_fee',
            arguments: [params.marketId,params.fee],
            typeArguments: [params.itemType],
            gasPayment: params.gasPaymentObjectId,
            gasBudget: 10000,
        }  
        return txn
      }
}