// Copyright 2019-2022 SwiftNFT Systems
// SPDX-License-Identifier: Apache-2.0
module swift_nft::market {
    use sui::object::{Self, ID, UID};
    use sui::url::{Self, Url};
    use std::ascii::String;
    use std::string;
    use sui::sui::SUI;
    use sui::coin::{Self, Coin};
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};
    use sui::dynamic_object_field as ofield;
    use sui::pay;
    use std::vector;
    use swift_nft::market_event;
    use swift_nft::err_code;
    use sui::vec_map;
    use std::type_name;
    use sui::dynamic_object_field;

    //let explicit_u8 = 1u8;
    ///Some basic information about Item's listing  in the market
    struct Listing<phantom Item: store + key> has store, key {
        id: UID,
        /// The Item of price
        price: u64,
        /// The Item of owner
        seller: address
    }

    ///Some basic information about Collection
    struct Collection<phantom Item: key+store> has key, store {
        id: UID,
        /// Name of the collection
        name: string::String,
        /// Description of the collection
        description: string::String,
        /// tags of the collection
        tags: vector<string::String>,
        ///logo_image of the collection
        logo_image: Url,
        ///featured_image of the collection
        featured_image: Url,
        ///website of the collection
        website: Url,
        ///twitter of the collection
        twitter: Url,
        /// discord of the collection
        discord: Url,
        /// Address that created this collection and As the administrator of the Collection
        receiver: address,
        /// Royalties collected by collction
        balance: Coin<SUI>,
        /// Royalty  fee of the collection
        fee: u64
    }

    ///Record some important information of the market
    struct Marketplace has key {
        id: UID,
        ///collection set of the marketplace
        collection: vec_map::VecMap<String, ID>,
        ///marketplace fee collected by marketplace
        balance: Coin<SUI>,
        ///marketplace fee  of the marketplace
        fee: u64,
    }

    struct WithdrawMarket has key {
        id: UID,
    }

    ///Initialize the marketplace object
    // fun create_market<TypeCoin>(ctx: &mut TxContext){
    //     //Initialize the marketplace object and set the marketpalce fee
    //     let market = Marketplace {
    //         id: object::new(ctx),
    //         collection: vec_set::empty(),
    //         balance: coin::zero<TypeCoin>(ctx),
    //         fee: 150,
    //     };
    //     market_event::market_created_event(object::id(&market), tx_context::sender(ctx));
    //
    //     //Create an object for collecting fees
    //     let profits = WithdrawMarket {
    //         id: object::new(ctx),
    //     };
    //
    //     transfer::share_object(market);
    //     transfer::transfer(profits, tx_context::sender(ctx));
    // }
    fun init(ctx: &mut TxContext) {
        //Initialize the marketplace object and set the marketpalce fee
        let market = Marketplace {
            id: object::new(ctx),
            collection: vec_map::empty<String, ID>(),
            balance: coin::zero<SUI>(ctx),
            fee: 150,
        };
        market_event::market_created_event(object::id(&market), tx_context::sender(ctx));

        //Create an object for collecting fees
        let profits = WithdrawMarket {
            id: object::new(ctx),
        };

        transfer::share_object(market);
        transfer::transfer(profits, tx_context::sender(ctx));
    }

    ///Creating a collection
    public entry fun create_collection<Item: key+store>(
        market: &mut Marketplace,
        name: vector<u8>,
        description: vector<u8>,
        tags: vector<vector<u8>>,
        logo_image: vector<u8>,
        featured_image: vector<u8>,
        website: vector<u8>,
        twitter: vector<u8>,
        discord: vector<u8>,
        fee: u64,
        ctx: &mut TxContext) {
        // Initialize some basic information about collection
        let collection = Collection<Item> {
            id: object::new(ctx),
            name: string::utf8(name),
            description: string::utf8(description),
            tags: to_string_vector(&mut tags),
            logo_image: url::new_unsafe_from_bytes(logo_image),
            featured_image: url::new_unsafe_from_bytes(featured_image),
            website: url::new_unsafe_from_bytes(website),
            twitter: url::new_unsafe_from_bytes(twitter),
            discord: url::new_unsafe_from_bytes(discord),
            receiver: tx_context::sender(ctx),
            balance: coin::zero<SUI>(ctx),
            fee,
        };

        let collection_id = object::id(&collection);
        market_event::collection_created_event(collection_id, tx_context::sender(ctx));
        let collection_type_name = type_name::into_string(type_name::get<Item>());
        vec_map::insert(&mut market.collection, collection_type_name, object::id(&collection));
        transfer::share_object(collection);
    }

    ///Listing NFT in the collection
    public entry fun list<Item: store+key>(collection: &mut Collection<Item>, item: Item,
                                           price: u64, ctx: &mut TxContext) {
        let item_id = object::id(&item);
        let id = object::new(ctx);

        ofield::add(&mut id, true, item);
        let listing = Listing<Item> {
            id,
            price,
            seller: tx_context::sender(ctx),
        };
        let listing_id = object::id(&listing);
        //Table
        // let operator_object=collection.objects
        //object_table::add(&mut collection.,item_id,listing);
        ofield::add(&mut collection.id, item_id, listing);

        market_event::item_list_event(object::id(collection), item_id, listing_id, tx_context::sender(ctx), price);
    }

    ///Adjusting the price of NFT
    public entry fun adjust_price<Item: store+key>(
        collection: &mut Collection<Item>,
        item_id: ID,
        price: u64,
        ctx: &mut TxContext) {
        let collection_id = object::id(collection);
        let listing = dynamic_object_field::borrow_mut<ID, Listing<Item>>(&mut collection.id, item_id);
        assert!(listing.seller == tx_context::sender(ctx), err_code::not_auth_operator());
        listing.price = price;
        market_event::item_adjust_price_event(collection_id, object::id(listing), tx_context::sender(ctx), price);
    }

    ///Cancel the listing of NFT
    public fun delist<Item: store+key>(collection: &mut Collection<Item>,
                                       item_id: ID,
                                       ctx: &mut TxContext): Item {
        //Get the list from the collection

        let listing = ofield::remove<ID, Listing<Item>>(&mut collection.id, item_id);
        let listing_id = object::id(&listing);
        //unpack
        let Listing<Item> {
            id,
            price,
            seller,
        } = listing;
        //Determine the owner's authority
        assert!(tx_context::sender(ctx) == seller, err_code::not_auth_operator());
        let item = ofield::remove<bool, Item>(&mut id, true);
        //emit event
        market_event::item_delisted_event(object::id(collection), item_id, listing_id, tx_context::sender(ctx), price);

        object::delete(id);
        item
    }


    ///purchase
    public fun buy_script<Item: store+key>(market: &mut Marketplace, collection: &mut Collection<Item>,
                                           item_id: ID,
                                           paid: &mut Coin<SUI>, ctx: &mut TxContext): Item {
        let listing = ofield::remove<ID, Listing<Item>>(&mut collection.id, item_id);
        let listing_id = object::id(&listing);
        let Listing<Item> {
            id,
            price,
            seller,
        } = listing;

        assert!(coin::value(paid) >= price, err_code::err_input_amount());

        let market_fee = price * market.fee / 10000;
        let collection_fee = price * collection.fee / 10000;
        let surplus = price - market_fee - collection_fee;

        assert!(surplus > 0, err_code::err_amount_is_zero());

        pay::split_and_transfer(paid, surplus, seller, ctx);

        let collection_value = coin::split<SUI>(paid, collection_fee, ctx);
        let market_value = coin::split<SUI>(paid, market_fee, ctx);

        coin::join(&mut market.balance, market_value);
        coin::join(&mut collection.balance, collection_value);

        let item = ofield::remove<bool, Item>(&mut id, true);

        market_event::item_puchased_event(object::id(collection), item_id, listing_id, seller, price);

        object::delete(id);
        item
    }

    ///purcahse muti NFT
    public entry fun buy_muti_item_script<Item: store+key>(
        market: &mut Marketplace,
        collection: &mut Collection<Item>,
        item_ids: vector<ID>,
        pay_list: vector<Coin<SUI>>,
        receiver: address,
        ctx: &mut TxContext
    ) {
        let paid = vector::pop_back(&mut pay_list);
        pay::join_vec<SUI>(&mut paid, pay_list);
        while (vector::length(&item_ids) != 0) {
            let ids = vector::pop_back(&mut item_ids);
            buy_and_take_script<Item>(market, collection, ids, &mut paid, receiver, ctx);
        };
        transfer::public_transfer(paid, tx_context::sender(ctx))
    }

    public entry fun buy_and_take_script<Item: store+key>(market: &mut Marketplace,
                                                          collection: &mut Collection<Item>,
                                                          item_id: ID,
                                                          paid: &mut Coin<SUI>,
                                                          receiver: address,
                                                          ctx: &mut TxContext) {
        transfer::public_transfer(buy_script<Item>(market, collection, item_id, paid, ctx), receiver)
    }

    public fun collect_profit_collection<Item: key+store>(
        collection: &mut Collection<Item>,
        receiver: address,
        ctx: &mut TxContext
    ) {
        assert!(tx_context::sender(ctx) == collection.receiver, err_code::not_auth_operator());
        let balances = coin::value(&mut collection.balance);
        let coins = coin::split(&mut collection.balance, balances, ctx);
        transfer::public_transfer(coins, receiver);
    }

    public entry fun collect_profits(
        _owner: &WithdrawMarket,
        market: &mut Marketplace,
        _receiver: address,
        ctx: &mut TxContext
    ) {
        let balances = coin::value(&mut market.balance);
        let coins = coin::split(&mut market.balance, balances, ctx);
        transfer::public_transfer(coins, tx_context::sender(ctx));
    }


    public entry fun delist_take<Item: key + store>(
        collection: &mut Collection<Item>,
        item_id: ID,
        ctx: &mut TxContext) {
        let item = delist<Item>(collection, item_id, ctx);
        transfer::public_transfer(item, tx_context::sender(ctx));
    }

    public entry fun delist_take_receiver<Item: key + store>(
        collection: &mut Collection<Item>,
        item_id: ID,
        receiver: address,
        ctx: &mut TxContext) {
        let item = delist<Item>(collection, item_id, ctx);
        transfer::public_transfer(item, receiver);
    }


    public entry fun update_collection_owner<Item: key+store>(
        colection: &mut Collection<Item>,
        owner: address,
        ctx: &mut TxContext
    ) {
        assert!(colection.receiver == tx_context::sender(ctx), err_code::not_auth_operator());
        colection.receiver = owner
    }

    public entry fun update_collection_fee<Item: key+store>(
        colection: &mut Collection<Item>,
        fee: u64,
        ctx: &mut TxContext
    ) {
        assert!(tx_context::sender(ctx) == colection.receiver, err_code::not_auth_operator());
        colection.fee = fee
    }

    public entry fun update_collection_twitter<Item: key+store>(
        colection: &mut Collection<Item>,
        twitter: vector<u8>,
        ctx: &mut TxContext
    ) {
        let twitter = url::new_unsafe_from_bytes(twitter);
        assert!(tx_context::sender(ctx) == colection.receiver, err_code::not_auth_operator());
        colection.twitter = twitter
    }


    public entry fun update_collection_website<Item: key+store>(
        colection: &mut Collection<Item>,
        website: vector<u8>,
        ctx: &mut TxContext
    ) {
        assert!(tx_context::sender(ctx) == colection.receiver, err_code::not_auth_operator());
        colection.website = url::new_unsafe_from_bytes(website)
    }

    public entry fun update_collection_discord<Item: key+store>(
        colection: &mut Collection<Item>,
        discord: vector<u8>,
        ctx: &mut TxContext
    ) {
        assert!(tx_context::sender(ctx) == colection.receiver, err_code::not_auth_operator());
        colection.discord = url::new_unsafe_from_bytes(discord)
    }

    public entry fun update_market_fee(
        _owner: &WithdrawMarket,
        market: &mut Marketplace,
        fee: u64,
        _ctx: &mut TxContext
    ) {
        market.fee = fee
    }

    public fun to_string_vector(
        vec: &mut vector<vector<u8>>
    ): vector<string::String>
    {
        let new_vec: vector<string::String> = vector::empty();

        let len = vector::length(vec);

        if (len == 0) {
            return new_vec
        };

        let i = 0;
        while (i < len) {
            let e = string::utf8(vector::pop_back(vec));
            vector::push_back(&mut new_vec, e);
            i = i + 1;
        };
        vector::reverse(&mut new_vec);
        new_vec
    }
}
