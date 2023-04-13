'use strict';

var sui_js = require('@mysten/sui.js');

/*! *****************************************************************************
Copyright (c) Microsoft Corporation.

Permission to use, copy, modify, and/or distribute this software for any
purpose with or without fee is hereby granted.

THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH
REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY
AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT,
INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM
LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR
OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR
PERFORMANCE OF THIS SOFTWARE.
***************************************************************************** */

function __awaiter(thisArg, _arguments, P, generator) {
    function adopt(value) { return value instanceof P ? value : new P(function (resolve) { resolve(value); }); }
    return new (P || (P = Promise))(function (resolve, reject) {
        function fulfilled(value) { try { step(generator.next(value)); } catch (e) { reject(e); } }
        function rejected(value) { try { step(generator["throw"](value)); } catch (e) { reject(e); } }
        function step(result) { result.done ? resolve(result.value) : adopt(result.value).then(fulfilled, rejected); }
        step((generator = generator.apply(thisArg, _arguments || [])).next());
    });
}

class MarketMoudle {
    get sdk() {
        return this._sdk;
    }
    constructor(sdk) {
        this._sdk = sdk;
    }
    getCollectionInfo(collectionId) {
        return __awaiter(this, void 0, void 0, function* () {
            const collectionObject = yield this._sdk.jsonRpcProvider.getObject(collectionId);
            const details = sui_js.getObjectFields(collectionObject);
            if (details == undefined) {
                return Promise.reject("Invaild collectionId");
            }
            const info = {
                collectionId,
                name: details === null || details === void 0 ? void 0 : details["name"],
                description: details === null || details === void 0 ? void 0 : details["description"],
                tags: details === null || details === void 0 ? void 0 : details["tags"],
                logo_image: details === null || details === void 0 ? void 0 : details["tags"],
                featured_image: details === null || details === void 0 ? void 0 : details["tags"],
                website: details === null || details === void 0 ? void 0 : details["website"],
                twitter: details === null || details === void 0 ? void 0 : details["twitter"],
                discord: details === null || details === void 0 ? void 0 : details["discord"],
                receiver: details === null || details === void 0 ? void 0 : details["receiver"],
                balance: details === null || details === void 0 ? void 0 : details["balance"],
                fee: details === null || details === void 0 ? void 0 : details["fee"]
            };
            return Promise.resolve(info);
        });
    }
    getItemInfo(itemId) {
        return __awaiter(this, void 0, void 0, function* () {
            const itemObject = yield this._sdk.jsonRpcProvider.getObject(itemId);
            let info = sui_js.getObjectFields(itemObject);
            return Promise.resolve(info);
        });
    }
    getCollectionItemids(collectionId) {
        return __awaiter(this, void 0, void 0, function* () {
            const subObject = yield this._sdk.jsonRpcProvider.getDynamicFields(collectionId);
            let itemIds = new Array(0);
            for (let i = 0; i < subObject.data.length; i++) {
                const itemId = yield this._sdk.jsonRpcProvider.getDynamicFields(subObject.data[i].objectId).then((result) => {
                    return result.data[0].objectId;
                });
                itemIds.push(itemId);
            }
            return Promise.resolve(itemIds);
        });
    }
    buildCreateCollectionTransaction(params) {
        const { packageObjectId } = this.sdk.networkOptions;
        const txn = {
            packageObjectId: packageObjectId,
            module: 'market',
            function: 'create_collection',
            arguments: [params.market, params.name, params.description, params.tags, params.logo_image, params.featured_image, params.website, params.twitter, params.discord],
            typeArguments: [params.itemType],
            gasPayment: params.gasPaymentObjectId,
            gasBudget: 10000,
        };
        return txn;
    }
    buildListingItemTransaction(params) {
        const { packageObjectId } = this.sdk.networkOptions;
        const txn = {
            packageObjectId: packageObjectId,
            module: 'market',
            function: 'list',
            arguments: [params.collectionId, params.itemId, params.price],
            typeArguments: [params.itemType],
            gasPayment: params.gasPaymentObjectId,
            gasBudget: 10000,
        };
        return txn;
    }
    buildAdjustPriceTransaction(params) {
        const { packageObjectId } = this.sdk.networkOptions;
        const txn = {
            packageObjectId: packageObjectId,
            module: 'market',
            function: 'adjust_price',
            arguments: [params.collectionId, params.itemId, params.price],
            typeArguments: [params.itemType],
            gasPayment: params.gasPaymentObjectId,
            gasBudget: 10000,
        };
        return txn;
    }
    buildDelistingItemTransaction(params) {
        const { packageObjectId } = this.sdk.networkOptions;
        const txn = {
            packageObjectId: packageObjectId,
            module: 'market',
            function: 'delist_take',
            arguments: [params.collectionId, params.itemId],
            typeArguments: [params.itemType],
            gasPayment: params.gasPaymentObjectId,
            gasBudget: 10000,
        };
        return txn;
    }
    buildPurchaseItemTransaction(params) {
        const { packageObjectId } = this.sdk.networkOptions;
        const txn = {
            packageObjectId: packageObjectId,
            module: 'market',
            function: 'buy_and_take_script',
            arguments: [params.marketId, params.collectionId, params.itemId, params.paidCoin, params.receiver],
            typeArguments: [params.itemType],
            gasPayment: params.gasPaymentObjectId,
            gasBudget: 10000,
        };
        return txn;
    }
    buildPurchaseMutilItemTransaction(params) {
        const { packageObjectId } = this.sdk.networkOptions;
        const txn = {
            packageObjectId: packageObjectId,
            module: 'market',
            function: 'buy_muti_item_script',
            arguments: [params.marketId, params.collectionId, params.itemIds, params.paidCoins, params.receiver],
            typeArguments: [params.itemType],
            gasPayment: params.gasPaymentObjectId,
            gasBudget: 10000,
        };
        return txn;
    }
    buildCollecProfitCollection(params) {
        const { packageObjectId } = this.sdk.networkOptions;
        const txn = {
            packageObjectId: packageObjectId,
            module: 'market',
            function: 'collect_profit_collection',
            arguments: [params.collectionId, params.receiver],
            typeArguments: [params.itemType],
            gasPayment: params.gasPaymentObjectId,
            gasBudget: 10000,
        };
        return txn;
    }
    buildCollecProfitMarket(params) {
        const { packageObjectId } = this.sdk.networkOptions;
        const txn = {
            packageObjectId: packageObjectId,
            module: 'market',
            function: 'collect_profits',
            arguments: [params.ownerObject, params.marketId, params.receiver],
            typeArguments: [params.itemType],
            gasPayment: params.gasPaymentObjectId,
            gasBudget: 10000,
        };
        return txn;
    }
    buildUpdateCollectionOwner(params) {
        const { packageObjectId } = this.sdk.networkOptions;
        const txn = {
            packageObjectId: packageObjectId,
            module: 'market',
            function: 'update_collection_owner',
            arguments: [params.collectionId, params.owner],
            typeArguments: [params.itemType],
            gasPayment: params.gasPaymentObjectId,
            gasBudget: 10000,
        };
        return txn;
    }
    buildUpdateCollectionfee(params) {
        const { packageObjectId } = this.sdk.networkOptions;
        const txn = {
            packageObjectId: packageObjectId,
            module: 'market',
            function: 'update_collection_fee',
            arguments: [params.collectionId, params.fee],
            typeArguments: [params.itemType],
            gasPayment: params.gasPaymentObjectId,
            gasBudget: 10000,
        };
        return txn;
    }
    buildUpdateCollectionTwitter(params) {
        const { packageObjectId } = this.sdk.networkOptions;
        const txn = {
            packageObjectId: packageObjectId,
            module: 'market',
            function: 'update_collection_twitter',
            arguments: [params.collectionId, params.social],
            typeArguments: [params.itemType],
            gasPayment: params.gasPaymentObjectId,
            gasBudget: 10000,
        };
        return txn;
    }
    buildUpdateCollectionWebsite(params) {
        const { packageObjectId } = this.sdk.networkOptions;
        const txn = {
            packageObjectId: packageObjectId,
            module: 'market',
            function: 'update_collection_website',
            arguments: [params.collectionId, params.social],
            typeArguments: [params.itemType],
            gasPayment: params.gasPaymentObjectId,
            gasBudget: 10000,
        };
        return txn;
    }
    buildUpdateCollectionDiscord(params) {
        const { packageObjectId } = this.sdk.networkOptions;
        const txn = {
            packageObjectId: packageObjectId,
            module: 'market',
            function: 'update_collection_discord',
            arguments: [params.collectionId, params.social],
            typeArguments: [params.itemType],
            gasPayment: params.gasPaymentObjectId,
            gasBudget: 10000,
        };
        return txn;
    }
    buildMarketFee(params) {
        const { packageObjectId } = this.sdk.networkOptions;
        const txn = {
            packageObjectId: packageObjectId,
            module: 'market',
            function: 'update_market_fee',
            arguments: [params.marketId, params.fee],
            typeArguments: [params.itemType],
            gasPayment: params.gasPaymentObjectId,
            gasBudget: 10000,
        };
        return txn;
    }
}

class SDK {
    get jsonRpcProvider() {
        return this._jsonRpcProvider;
    }
    get Market() {
        return this._market;
    }
    get networkOptions() {
        return this._networkConfiguration;
    }
    get serializer() {
        return this._serializer;
    }
    constructor(networkConfiguration) {
        this._jsonRpcProvider = new sui_js.JsonRpcProvider(networkConfiguration.network);
        this._serializer = new sui_js.RpcTxnDataSerializer(this._jsonRpcProvider.connection.fullnode, this._jsonRpcProvider.options.skipDataValidation);
        this._networkConfiguration = networkConfiguration;
        this._market = new MarketMoudle(this);
    }
}

class NetworkConfiguration {
    constructor(networkName, network, packageObjectId, marketObjectId, isMainNet = false) {
        this.networkName = networkName;
        this.network = network;
        this.packageObjectId = packageObjectId;
        this.marketObjectId = marketObjectId;
        this.isMainNet = isMainNet;
    }
}
const devconnection = new sui_js.Connection({
    fullnode: 'https://fullnode.devnet.sui.io',
    faucet: 'https://faucet.devnet.sui.io/gas',
});
new sui_js.Connection({
    fullnode: 'https://fullnode.testnet.sui.io',
    faucet: 'https://faucet.testnet.sui.io/gas',
});
const DEVNET_CONFIG = new NetworkConfiguration('devnet', devconnection, '0x401e2d45f4a169b965d57e747afc9ed02ef22a76', '0x8d20d6cb64e6e7f6c47f6b7b0037dbb1351b5be0');

exports.DEVNET_CONFIG = DEVNET_CONFIG;
exports.MarketMoudle = MarketMoudle;
exports.NetworkConfiguration = NetworkConfiguration;
exports.SDK = SDK;
//# sourceMappingURL=index.js.map
