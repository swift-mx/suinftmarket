module swift_nft::safe_market {
    use sui::object::{ID, UID};
    use swift_nft::safe_pool::OwnerCap;
    use swift_nft::safe_collection::{Self, Collection};
    use std::string;
    use sui::vec_set::VecSet;
    use sui::url::Url;
    use sui::coin::{Self, Coin};
    use sui::pay;
    use sui::tx_context::TxContext;


    struct SafeStandardMarket has key, store {
        id: UID,
        collection: VecSet<ID>,
        ///marketplace fee collected by marketplace
        receiver: address,
        ///marketplace fee  of the marketplace
        fee: u64,
    }

    // 1/10000===== 0.01%
    struct CustomRoyalty<phantom CoinType>has store {
        receiver: address,
        fee: u64,
    }

    struct CustomBorrowRate<phantom CoinType>has store {
        receiver: address,
        fee: u64
    }

    struct CustomFlashloanRate<phantom CoinType>has store {
        receiver: address,
        fee: u64
    }

    struct MetaData has store {
        tags: vector<string::String>,
        logo_image: Url,
        featured_image: Url,
        website: Url,
        tw: Url,
        discord: Url,
    }


    public fun list_market_item<Item: key+store, M: store, BorrowRate: store, FlashloanRate: store, CoinType>(
        self: &mut Collection<Item, MetaData, CustomRoyalty<CoinType>, CustomBorrowRate<CoinType>, CustomFlashloanRate<CoinType>>,
        ownerCap: &OwnerCap<Item>,
        price: u64,
        ctx: &mut TxContext
    ) {
        safe_collection::list_item<Item, MetaData, CustomRoyalty<CoinType>, CustomBorrowRate<CoinType>, CustomFlashloanRate<CoinType>>(
            self,
            ownerCap,
            price,
            ctx
        )
    }

    public fun purchase_market_item<Item: key+store, M: store, BorrowRate: store, FlashloanRate: store, CoinType>(
        market: &SafeStandardMarket,
        collection: &mut Collection<Item, MetaData, CustomRoyalty<CoinType>, CustomBorrowRate<CoinType>, CustomFlashloanRate<CoinType>>,
        item_id: ID,
        paid: &mut Coin<CoinType>,
        ctx: &mut TxContext
    ): Item {
        let price = safe_collection::get_listing_price<Item, MetaData, CustomRoyalty<CoinType>, CustomBorrowRate<CoinType>, CustomFlashloanRate<CoinType>>(
            collection,
            item_id
        );
        assert!(coin::value(paid) >= price, 1);

        //1.execute market legal
        let market_fee = price * market.fee / 10000;

        //2.execute CustomRoyalty legal
        let collection_royalty = safe_collection::get_immut_royalty<Item, MetaData, CustomRoyalty<CoinType>, CustomBorrowRate<CoinType>, CustomFlashloanRate<CoinType>>(
            collection
        );

        let royalty_fee = price * collection_royalty.fee / 10000;

        let actual_price = price - market_fee - royalty_fee;

        //transfer market_fee to market owner
        pay::split_and_transfer(paid, market_fee, market.receiver, ctx);
        //transfer royalty_fee to collection owner
        pay::split_and_transfer(paid, royalty_fee, collection_royalty.receiver, ctx);

        let item = safe_collection::purchase_item<Item, MetaData, CustomRoyalty<CoinType>, CustomBorrowRate<CoinType>, CustomFlashloanRate<CoinType>>(
            collection,
            item_id
        );

        let listing_receiver = safe_collection::get_listing_receiver<Item, MetaData, CustomRoyalty<CoinType>, CustomBorrowRate<CoinType>, CustomFlashloanRate<CoinType>>(
            collection,
            item_id
        );

        pay::split_and_transfer(paid, actual_price, listing_receiver, ctx);

        item
    }

    public fun unlist_market_item<Item: key+store, M: store, BorrowRate: store, FlashloanRate: store, CoinType>(
        self: &mut Collection<Item, MetaData, CustomRoyalty<CoinType>, CustomBorrowRate<CoinType>, CustomFlashloanRate<CoinType>>,
        item_id: ID,
        ctx: &mut TxContext
    ) {
        safe_collection::unlist_item<Item, MetaData, CustomRoyalty<CoinType>, CustomBorrowRate<CoinType>, CustomFlashloanRate<CoinType>>(
            self,
            item_id,
            ctx
        )
    }

    //todo Redesign
    // public fun immutable_borrowing_market_item<Item: key+store,M:store,BorrowRate:store,FlashloanRate: store,CoinType>(
    //     self: &mut Collection<Item,MetaData,CustomRoyalty<CoinType>,CustomBorrowRate<CoinType>,CustomFlashloanRate<CoinType>>,
    //     borrowed: &mut Borrowed<Item>,
    //     start: u64,
    //     end: u64,
    //     price: u64,
    //     borrower: address,
    //     ctx: &mut TxContext
    // ):&Item{
    //     //0.royalty
    //
    //     //1.check time
    //     assert!(tx_context::epoch(ctx)>=start,1);
    //     assert!(end>=tx_context::epoch(ctx),2);
    //     //2.execute borrowing
    //
    //
    //     // safe_collection::borrow_immutable_item<Item,MetaData,CustomRoyalty<CoinType>,CustomBorrowRate<CoinType>,CustomFlashloanRate<CoinType>>(
    //     //     self,
    //     //     borrowed,
    //     //     start,
    //     //     end,
    //     //     price,
    //     //     borrower
    //     // )
    //
    // }

    //todo Redesign
    // public fun mutable_borrowing_market_item<Item: key+store,M:store,BorrowRate:store,FlashloanRate: store,CoinType>(
    //     self: &mut Collection<Item,MetaData,CustomRoyalty<CoinType>,CustomBorrowRate<CoinType>,CustomFlashloanRate<CoinType>>,
    //     borrowed: &mut Borrowed<Item>,
    //     start: u64,
    //     end: u64,
    //     price: u64,
    //     borrower: address,
    // ):&mut Item{
    //     safe_collection::borrow_mutable_item<Item,MetaData,CustomRoyalty<CoinType>,CustomBorrowRate<CoinType>,CustomFlashloanRate<CoinType>>(
    //         self,
    //         borrowed,
    //         start,
    //         end,
    //         price,
    //         borrower
    //     )
    // }
}
