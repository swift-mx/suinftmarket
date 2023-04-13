export type CreateCollectionTXPayloadParams={
    market: string,
    name: string,
    description: string,
    tags: string[],
    logo_image: string,
    featured_image: string,
    website: string,
    twitter: string,
    discord: string,
    fee: number,
    itemType: string,
    gasPaymentObjectId: string;
}

export type ListingItemTxPayloadParams={
    collectionId: string,
    itemId: string,
    price: number,
    itemType: string,
    gasPaymentObjectId: string;
}
export type AdjustPriceTxPayloadParams={
    collectionId: string,
    itemId: string,
    price: number,
    itemType: string,
    gasPaymentObjectId: string;
}

export type DelistingItemTxPayloadParams={
    collectionId: string,
    itemId: string,
    itemType: string,
    gasPaymentObjectId: string;
}
export type PurchaseItemTxPayloadParams={
    marketId:string,
    collectionId: string,
    itemId: string,
    paidCoin:string,
    receiver: string,
    itemType: string,
    gasPaymentObjectId: string;
}

export type PurchaseMutilItemTxPayloadParams={
    marketId:string,
    collectionId: string,
    itemIds: string[],
    paidCoins:string[],
    receiver: string,
    itemType: string,
    gasPaymentObjectId: string;
}

export type CollectProfitCollectionTxPayloadParams={
    collectionId:string,
    receiver: string,
    itemType: string,
    gasPaymentObjectId: string;
}
export type CollectProfitsTxPayloadParams={
    ownerObject:string,
    marketId: string,
    receiver: string,
    itemType: string,
    gasPaymentObjectId: string;
}
export type UpdateCollectionOwnerTxPayloadParams={
    collectionId: string,
    owner: string,
    itemType: string,
    gasPaymentObjectId: string;
}
export type UpdateCollectionFeeTxPayloadParams={
    collectionId: string,
    fee: number,
    itemType: string,
    gasPaymentObjectId: string;
}
export type UpdateCollectionInfoTxPayloadParams={
    collectionId: string,
    social: string,
    itemType: string,
    gasPaymentObjectId: string;
}
export type UpdateMarketFeeTxPayloadParams={
    marketId:string,
    fee: number,
    itemType: string,
    gasPaymentObjectId: string;
}