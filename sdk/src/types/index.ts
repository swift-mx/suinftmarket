

export type ListingInfo={
    listing_id: string,
    item_id: string,
    item_type: string,
    price: number,
    seller: string,
}


export type CollectionInfo={
    collectionId: string,
    name: string,
    description: string,
    tags: string[],
    logo_image: string,
    featured_image: string,
    website: string,
    twitter: string,
    discord: string,
    receiver: string,
    balance: Object,
    fee: number
}


export type TxPayloadCallFunction = {
    packageObjectId: string;
    module: string;
    function: string;
    typeArguments: string[];
    arguments: string[];
    gasBudget: number;
};



