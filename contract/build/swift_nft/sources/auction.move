// Copyright 2019-2022 SwiftNFT Systems
// SPDX-License-Identifier: Apache-2.0
module swift_nft::auction {
    use sui::coin::{Self, Coin};
    use sui::object::{Self, UID, ID};
    use std::option::{Self, Option};
    use sui::tx_context::{Self, TxContext};
    use sui::transfer;
    use sui::dynamic_object_field as ofiled;
    use swift_nft::auction_event;
    ///Some basic information about NFT auctions
    struct ItemAuctionInfo<Item: key+store, phantom CoinType>has key, store {
        id: UID,
        ///Storage of NFT entities to be auctioned
        item: Option<Item>,
        ///staring price
        min_price: u64,
        ///staring auction time
        start: u64,
        ///end auction time
        end: u64,
        ///Funds for depositing auction items
        funds: Option<Coin<CoinType>>,
        ///Current Highest Bidder
        highest_bidder: address,
    }

    ///NFT Auction Object
    struct ItemAuction<phantom Item> has key {
        id: UID,
        ///Auction creator
        creator: address,
        ///NFT ownership
        item_id: ID,
    }


    const EEpochNotYetEnded: u64 = 0;
    const ENotOwner: u64 = 1;
    const ENoExceedsMinPrice: u64 = 2;
    const ENoExceedsHighestBid: u64 = 3;
    const EBidTimeNoStart: u64 = 4;
    const EBidTimeAlReadyEnd: u64 = 5;
    const EBidTimeNoEnd: u64 = 6;
    const EBidPriceTooLow: u64 = 7;


    ///Returns the owner who created the auction
    public fun auction_creator<Item: key + store>(auction: &ItemAuction<Item>): address {
        auction.creator
    }

    ///Open an NFT auction
    public entry fun create_auction<Item: key + store, CoinType>(
        item: Item,
        min_price: u64,
        start: u64,
        end: u64,
        ctx: &mut TxContext
    ) {
        //get the  ID of object
        let item_id = object::id(&item);
        //Wrapping the action object
        let auction = ItemAuction<Item> {
            id: object::new(ctx),
            creator: tx_context::sender(ctx),
            item_id
        };
        //Constructing auction information object and acts as a dynamic child of the auction object
        let auction_info = ItemAuctionInfo<Item, CoinType> {
            id: object::new(ctx),
            item: option::some(item),
            min_price,
            start,
            end,
            funds: option::none(),
            highest_bidder: tx_context::sender(ctx),
        };
        //emit create_auction_event
        auction_event::create_auction_event(
            object::id(&auction),
            item_id,
            tx_context::sender(ctx),
            min_price,
            start,
            end
        );

        ofiled::add(&mut auction.id, item_id, auction_info);
        //share object
        transfer::share_object(auction);
    }

    public entry fun bid_auction<Item: key + store, CoinType>(auction: &mut ItemAuction<Item>,
                                                      funds: Coin<CoinType>,
                                                      ctx: &mut TxContext) {
        let item_id = auction.item_id;
        let auction_id = object::id(auction);
        let item_info = ofiled::borrow_mut<ID, ItemAuctionInfo<Item, CoinType>>(&mut auction.id, item_id);
        //check that the NFT of the auction is in effect
        assert!(tx_context::epoch(ctx) >= item_info.start, EBidTimeNoStart);
        assert!(tx_context::epoch(ctx) <= item_info.end, EBidTimeAlReadyEnd);
        //Check if the current bid exceeds the minimum bid
        let bid_amount = coin::value(&funds);
        assert!(bid_amount >= item_info.min_price, ENoExceedsMinPrice);
        //Is it a first time bid
        if (option::is_none(&item_info.funds)) {
            option::fill(&mut item_info.funds, funds);
            auction_event::item_bid_event(auction_id, item_id, tx_context::sender(ctx), bid_amount);
            item_info.highest_bidder = tx_context::sender(ctx);
        }else {
            //This bid exceeds the highest bid

            let current_highest_amount = coin::value(option::borrow(&item_info.funds));
            assert!(bid_amount > current_highest_amount, ENoExceedsHighestBid);
            let pre_bid = option::swap(&mut item_info.funds, funds);
            let amount = coin::value(&pre_bid);

            auction_event::item_bid_event(auction_id, item_id, tx_context::sender(ctx), amount);

            transfer::public_transfer(pre_bid, item_info.highest_bidder);
            item_info.highest_bidder = tx_context::sender(ctx);
        }
    }

    ///Complete of this auction
    public entry fun complete_auction<Item: key + store, CoinType>(
        auction: &mut ItemAuction<Item>,
        ctx: &mut TxContext
    ) {
        let item_id = auction.item_id;
        let item_info = ofiled::remove<ID, ItemAuctionInfo<Item, CoinType>>(&mut auction.id, item_id);

        let ItemAuctionInfo<Item, CoinType> {
            id,
            item,
            min_price,
            start: _,
            end,
            funds,
            highest_bidder,
        } = item_info;
        //Check if this auction is ready to end
        assert!(tx_context::epoch(ctx) > end, EBidTimeNoEnd);
        //Take out NFT
        let auction_item = option::extract(&mut item);
        //Take out funds
        let fund = option::extract(&mut funds);

        assert!(coin::value(&fund) >= min_price, EBidPriceTooLow);

        auction_event::item_auction_compeleted_event(object::id(auction), highest_bidder, coin::value(&fund));

        //swap
        transfer::public_transfer(auction_item, highest_bidder);

        transfer::public_transfer(fund, auction.creator);

        object::delete(id);
        option::destroy_none(item);
        option::destroy_none(funds);
    }
}