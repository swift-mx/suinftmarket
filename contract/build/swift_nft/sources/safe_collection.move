// Copyright 2019-2022 SwiftNFT Systems
// SPDX-License-Identifier: Apache-2.0
module swift_nft::safe_collection {
    use sui::object::{Self, UID, ID};
    use std::string::{String};
    use sui::tx_context::{Self, TxContext};
    use swift_nft::safe_pool::{Self, SafePool, OwnerCap, BorrowCap, TransferCap, Borrowed, FlashLoanReceipt};
    use sui::object_table::{Self, ObjectTable};
    use sui::table::{Table};
    use sui::transfer;
    use sui::table;
    use std::vector;
    friend swift_nft::safe_market;

    struct Listing<phantom Item: key+store>has store {
        item_id: ID,
        price: u64,
        seller: address,
        transferCap: TransferCap<Item>
    }

    struct ListingBorrow<phantom Item: key+store>has store {
        item_id: ID,
        price: u64,
        seller: address,
        transferCap: Borrowed<Item>
    }

    ///Fixed price in range time/Charging rent by the day
    struct Borrowing<phantom Item: key+store> has store {
        item_id: ID,
        start: u64,
        end: u64,
        price: u64,
        borrower: address,
        active: bool,
    }

    struct Collection<phantom Item: key+store, M: store, Royalty: store, BorrowRate: store, FlashloanRate: store> has key, store {
        id: UID,
        /// Address that created this collection
        creator: address,
        /// Name of the collection. TODO: should this just be T.name?
        name: String,
        /// Description of the collection
        description: String,
        pool_id: ID,
        pool: ObjectTable<ID, SafePool<Item>>,
        list: Table<ID, Listing<Item>>,
        mutable_borrowing: Table<ID, Borrowing<Item>>,
        imuutable_borrowing: Table<ID, vector<Borrowing<Item>>>,
        custom_metadata: M,
        royalty: Royalty,
        borrow_rate: BorrowRate,
        flash_loan_rate: FlashloanRate,
    }

    public fun create<Item: key+store, M: store, Royalty: store, BorrowRate: store, FlashloanRate: store>(
        name: String,
        description: String,
        custom_metadata: M,
        royalty: Royalty,
        borrow_rate: BorrowRate,
        flash_loan_rate: FlashloanRate,
        ctx: &mut TxContext,
    ) {
        let pool = safe_pool::create<Item>(ctx);
        let safe_id = object::id(&pool);
        let collection = Collection<Item, M, Royalty, BorrowRate, FlashloanRate> {
            id: object::new(ctx),
            creator: tx_context::sender(ctx),
            name,
            description,
            pool_id: safe_id,
            pool: object_table::new<ID, SafePool<Item>>(ctx),
            list: table::new(ctx),
            mutable_borrowing: table::new(ctx),
            imuutable_borrowing: table::new(ctx),
            custom_metadata,
            royalty,
            borrow_rate,
            flash_loan_rate,
        };
        object_table::add(&mut collection.pool, safe_id, pool);
        transfer::share_object(collection)
    }

    ///Generate Listing and add it to the table
    // public  fun list_item<Item: key+store,M:store,Royalty: store,BorrowRate:store,FlashloanRate: store>(
    //     self: &mut Collection<Item,M,Royalty,BorrowRate,FlashloanRate>,
    //     transferCap: TransferCap<Item>,
    //     price :u64,
    //     ctx: &mut TxContext
    // ){
    //     //Get item_id through TransferCap
    //     let item_id=safe_pool::get_transferCap_item_id(&transferCap);
    //     //construct listing
    //     let listing=Listing<Item>{
    //         item_id,
    //         price,
    //         seller: tx_context::sender(ctx),
    //         transferCap
    //     };
    //     //add listing to the table
    //     table::add(&mut self.list,item_id,listing)
    // }
    //
    public fun list_item<Item: key+store, M: store, Royalty: store, BorrowRate: store, FlashloanRate: store>(
        self: &mut Collection<Item, M, Royalty, BorrowRate, FlashloanRate>,
        ownerCap: &OwnerCap<Item>,
        price: u64,
        ctx: &mut TxContext
    ) {
        let pool = object_table::borrow_mut(&mut self.pool, self.pool_id);
        let item_id = safe_pool::get_ownerCap_item_id(ownerCap);
        let transferCap = safe_pool::sell_nft(pool, ownerCap, item_id, ctx);

        //construct listing
        let listing = Listing<Item> {
            item_id,
            price,
            seller: tx_context::sender(ctx),
            transferCap
        };
        //add listing to the table
        table::add(&mut self.list, item_id, listing)
    }

    ///Remove Listing from the table and Deconstruction Listing
    public fun unlist_item<Item: key+store, M: store, Royalty: store, BorrowRate: store, FlashloanRate: store>(
        self: &mut Collection<Item, M, Royalty, BorrowRate, FlashloanRate>,
        item_id: ID,
        _ctx: &mut TxContext
    ) {
        let listing = table::remove(&mut self.list, item_id);
        let Listing<Item> {
            item_id: _,
            price: _,
            seller: _,
            transferCap
        } = listing;
        safe_pool::destory_transferCap(transferCap)
    }

    public fun get_listing_receiver<Item: key+store, M: store, Royalty: store, BorrowRate: store, FlashloanRate: store>(
        self: &mut Collection<Item, M, Royalty, BorrowRate, FlashloanRate>,
        item_id: ID,
    ): address {
        let listing = table::borrow<ID, Listing<Item>>(&self.list, item_id);
        listing.seller
    }


    public(friend) fun generate_borrow_immutable_item<Item: key+store, M: store, Royalty: store, BorrowRate: store, FlashloanRate: store>(
        self: &mut Collection<Item, M, Royalty, BorrowRate, FlashloanRate>,
        borrowCap: &BorrowCap<Item>,
        start: u64,
        end: u64,
        price: u64,
        borrower: address,
        ctx: &mut TxContext
    ): Borrowed<Item> {
        let item_id = safe_pool::get_borrowCap_item_id(borrowCap);
        let pool = object_table::borrow_mut(&mut self.pool, self.pool_id);
        let borrowed = safe_pool::borrow_nft(pool, borrowCap, item_id, false, ctx);
        let borrowing = Borrowing<Item> {
            item_id,
            start,
            end,
            price,
            borrower,
            active: false,
        };

        //<ID,VecMap<ID,Borrowing<Item>>>
        let immutable_borrowing = table::borrow_mut<ID, vector<Borrowing<Item>>>(
            &mut self.imuutable_borrowing,
            item_id
        );

        vector::push_back(immutable_borrowing, borrowing);
        // borrowing
        borrowed
    }

    public(friend) fun deal_borrow_immutable_item<Item: key+store, M: store, Royalty: store, BorrowRate: store, FlashloanRate: store>(
        self: &mut Collection<Item, M, Royalty, BorrowRate, FlashloanRate>,
        borrowed: Borrowed<Item>,
        index: u64,
    ): Borrowed<Item> {
        // let pool=object_table::borrow_mut(&mut self.pool,self.pool_id);
        let item_id = safe_pool::get_borrowed_item_id(&borrowed);
        let borrowing_vector = table::borrow_mut<ID, vector<Borrowing<Item>>>(&mut self.imuutable_borrowing, item_id);
        let borrowing = vector::remove(borrowing_vector, index);

        let Borrowing<Item> {
            item_id: _,
            start: _,
            end: _,
            price: _,
            borrower: _,
            active: _,
        } = borrowing;
        borrowed
    }

    public(friend) fun borrow_immutable_item<Item: key+store, M: store, Royalty: store, BorrowRate: store, FlashloanRate: store>(
        self: &mut Collection<Item, M, Royalty, BorrowRate, FlashloanRate>,
        borrowed: &mut Borrowed<Item>,
    ): &Item {
        let pool = object_table::borrow_mut(&mut self.pool, self.pool_id);
        safe_pool::get_nft(pool, borrowed)
    }


    public(friend) fun generate_borrow_mutable_item<Item: key+store, M: store, Royalty: store, BorrowRate: store, FlashloanRate: store>(
        self: &mut Collection<Item, M, Royalty, BorrowRate, FlashloanRate>,
        borrowCap: &BorrowCap<Item>,
        start: u64,
        end: u64,
        price: u64,
        borrower: address,
        ctx: &mut TxContext
    ): Borrowed<Item> {
        let item_id = safe_pool::get_borrowCap_item_id(borrowCap);
        let pool = object_table::borrow_mut(&mut self.pool, self.pool_id);
        let borrowed = safe_pool::borrow_nft(pool, borrowCap, item_id, false, ctx);
        let borrowing = Borrowing<Item> {
            item_id,
            start,
            end,
            price,
            borrower,
            active: false,
        };
        table::add(&mut self.mutable_borrowing, item_id, borrowing);
        borrowed
    }

    public(friend) fun deal_borrow_mutable_item<Item: key+store, M: store, Royalty: store, BorrowRate: store, FlashloanRate: store>(
        self: &mut Collection<Item, M, Royalty, BorrowRate, FlashloanRate>,
        borrowed: Borrowed<Item>,
    ): Borrowed<Item> {
        // let pool=object_table::borrow_mut(&mut self.pool,self.pool_id);
        let item_id = safe_pool::get_borrowed_item_id(&borrowed);
        let borrowing = table::remove(&mut self.mutable_borrowing, item_id);

        let Borrowing<Item> {
            item_id: _,
            start: _,
            end: _,
            price: _,
            borrower: _,
            active: _,
        } = borrowing;
        borrowed
    }

    public(friend) fun borrow_mutable_item<Item: key+store, M: store, Royalty: store, BorrowRate: store, FlashloanRate: store>(
        self: &mut Collection<Item, M, Royalty, BorrowRate, FlashloanRate>,
        borrowed: &mut Borrowed<Item>,
    ): &mut Item {
        let pool = object_table::borrow_mut(&mut self.pool, self.pool_id);
        safe_pool::get_nft_mut(pool, borrowed)
    }

    ///tdodo  replay_immutable_item
    // public(friend) fun replay_immutable_item<Item: key+store,M:store,Royalty: store,BorrowRate:store,FlashloanRate: store>(
    //     self: &mut Collection<Item,M,Royalty,BorrowRate,FlashloanRate>,
    //     borrowed: &mut Borrowed<Item>,
    // )

    // public(friend) fun borrow_mutable_item<Item: key+store,M:store,Royalty: store,BorrowRate:store,FlashloanRate: store>(
    //     self: &mut Collection<Item,M,Royalty,BorrowRate,FlashloanRate>,
    //     borrowed: &mut Borrowed<Item>,
    //     start: u64,
    //     end: u64,
    //     price: u64,
    //     borrower: address,
    // ):&mut Item{
    //     let pool=object_table::borrow_mut(&mut self.pool,self.pool_id);
    //     let item_id=safe_pool::get_borrowed_item_id(borrowed);
    //     let borrowing=Borrowing<Item>{
    //         item_id,
    //         start,
    //         end,
    //         price,
    //         borrower,
    //         active:true,
    //     };
    //     table::add(&mut self.mutable_borrowing,item_id,borrowing);
    //     safe_pool::get_nft_mut(pool,borrowed)
    // }


    ///tdodo  replay_mutable_item
    // public(friend) fun replay_imutable_item<Item: key+store,M:store,Royalty: store,BorrowRate:store,FlashloanRate: store>(
    //     self: &mut Collection<Item,M,Royalty,BorrowRate,FlashloanRate>,
    //     borrowed: &mut Borrowed<Item>,
    // )

    public fun add_item<Item: key+store, M: store, Royalty: store, BorrowRate: store, FlashloanRate: store>(
        self: &mut Collection<Item, M, Royalty, BorrowRate, FlashloanRate>,
        item: Item,
        ctx: &mut TxContext,
    ): (OwnerCap<Item>, BorrowCap<Item>) {
        let safe_pool = object_table::borrow_mut(&mut self.pool, self.pool_id);
        safe_pool::add_item(safe_pool, item, ctx)
    }

    public fun remove_item<Item: key+store, M: store, Royalty: store, BorrowRate: store, FlashloanRate: store>(
        self: &mut Collection<Item, M, Royalty, BorrowRate, FlashloanRate>,
        owner_cap: &OwnerCap<Item>,
        item_id: ID,
    ): Item {
        let safe_pool = object_table::borrow_mut(&mut self.pool, self.pool_id);
        safe_pool::remove_item(safe_pool, owner_cap, item_id)
    }


    public(friend) fun purchase_item<Item: key+store, M: store, Royalty: store, BorrowRate: store, FlashloanRate: store>(
        self: &mut Collection<Item, M, Royalty, BorrowRate, FlashloanRate>,
        item_id: ID,
    ): Item {
        let safe_pool = object_table::borrow_mut(&mut self.pool, self.pool_id);
        let listing = table::remove(&mut self.list, item_id);

        let Listing<Item> {
            item_id: _,
            price: _,
            seller: _,
            transferCap
        } = listing;
        safe_pool::buy_nft(safe_pool, transferCap, item_id)
    }

    public fun generate_transfer_cap<Item: key+store, M: store, Royalty: store, BorrowRate: store, FlashloanRate: store>(
        self: &mut Collection<Item, M, Royalty, BorrowRate, FlashloanRate>,
        owner_cap: &OwnerCap<Item>,
        item_id: ID,
        ctx: &mut TxContext
    ): TransferCap<Item> {
        let safe_pool = object_table::borrow_mut(&mut self.pool, self.pool_id);
        safe_pool::sell_nft(safe_pool, owner_cap, item_id, ctx)
    }


    public fun generate_borrowed_cap<Item: key+store, M: store, Royalty: store, BorrowRate: store, FlashloanRate: store>(
        self: &mut Collection<Item, M, Royalty, BorrowRate, FlashloanRate>,
        borrow_cap: &BorrowCap<Item>,
        item_id: ID,
        active: bool,
        ctx: &mut TxContext
    ): Borrowed<Item> {
        let safe_pool = object_table::borrow_mut(&mut self.pool, self.pool_id);
        safe_pool::borrow_nft(safe_pool, borrow_cap, item_id, active, ctx)
    }

    public fun destory_borrowed_cap<Item: key+store, M: store, Royalty: store, BorrowRate: store, FlashloanRate: store>(
        self: &mut Collection<Item, M, Royalty, BorrowRate, FlashloanRate>,
        borrow_cap: Borrowed<Item>
    ) {
        let safe_pool = object_table::borrow_mut(&mut self.pool, self.pool_id);
        safe_pool::unborrow_nft(safe_pool, borrow_cap)
    }

    public fun get_item_mut<Item: key+store, M: store, Royalty: store, BorrowRate: store, FlashloanRate: store>(
        self: &mut Collection<Item, M, Royalty, BorrowRate, FlashloanRate>,
        borrowed: &mut Borrowed<Item>
    ): &mut Item {
        let safe_pool = object_table::borrow_mut(&mut self.pool, self.pool_id);
        safe_pool::get_nft_mut(safe_pool, borrowed)
    }

    public fun get_item_immut<Item: key+store, M: store, Royalty: store, BorrowRate: store, FlashloanRate: store>(
        self: &mut Collection<Item, M, Royalty, BorrowRate, FlashloanRate>,
        borrowed: &mut Borrowed<Item>
    ): & Item {
        let safe_pool = object_table::borrow_mut(&mut self.pool, self.pool_id);
        safe_pool::get_nft(safe_pool, borrowed)
    }

    public fun flashloan_item<Item: key+store, M: store, Royalty: store, BorrowRate: store, FlashloanRate: store>(
        self: &mut Collection<Item, M, Royalty, BorrowRate, FlashloanRate>,
        item_id: ID,
    ): (Item, FlashLoanReceipt<Item>) {
        let safe_pool = object_table::borrow_mut(&mut self.pool, self.pool_id);
        safe_pool::flash_loan_item(safe_pool, item_id)
    }

    public fun replay_item<Item: key+store, M: store, Royalty: store, BorrowRate: store, FlashloanRate: store>(
        self: &mut Collection<Item, M, Royalty, BorrowRate, FlashloanRate>,
        receipt: FlashLoanReceipt<Item>,
        item: Item
    ) {
        let safe_pool = object_table::borrow_mut(&mut self.pool, self.pool_id);
        safe_pool::replay_item(safe_pool, receipt, item)
    }


    public fun get_immut_royalty<Item: key+store, M: store, Royalty: store, BorrowRate: store, FlashloanRate: store>(
        self: &Collection<Item, M, Royalty, BorrowRate, FlashloanRate>): &Royalty {
        return &self.royalty
    }


    ///Get the price of the list marketplace item
    public fun get_listing_price<Item: key+store, M: store, Royalty: store, BorrowRate: store, FlashloanRate: store>(
        self: &Collection<Item, M, Royalty, BorrowRate, FlashloanRate>,
        item_id: ID,
    ): u64 {
        let listing = table::borrow(&self.list, item_id);
        listing.price
    }
    // ///Get the owner of the list marketplace item
    // public  fun get_listing_owner<Item: key+store,M:store,Royalty: store,BorrowRate:store,FlashloanRate: store>(
    //     self: &Collection<Item,M,Royalty,BorrowRate,FlashloanRate>,
    //     item_id: ID,
    // ): address{
    //     let listing= table::borrow(&self.list,item_id);
    //     listing.seller
    // }

    public fun get_collection_receiver<Item: key+store, M: store, Royalty: store, BorrowRate: store, FlashloanRate: store>(
        self: &Collection<Item, M, Royalty, BorrowRate, FlashloanRate>): address {
        self.creator
    }
}
