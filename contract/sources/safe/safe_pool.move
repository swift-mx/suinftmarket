// Copyright 2019-2022 SwiftNFT Systems
// SPDX-License-Identifier: Apache-2.0
module swift_nft::safe_pool {

    use sui::object::{Self, UID, ID};
    use sui::object_table::{Self, ObjectTable};
    use sui::table::{Self, Table};
    use sui::vec_map::{Self, VecMap};
    use sui::vec_set::{Self, VecSet};
    use std::string::String;
    use sui::tx_context::TxContext;
    friend swift_nft::safe_collection;
    ///Record some basic information about the financialization of NFT
    struct SafePool<phantom Item: key+store> has key, store {
        id: UID,
        ///The set of NFTs stored in the pool
        nfts: ObjectTable<ID, Item>,
        nicknames: Table<String, ID>,
        ///The NFTs currently available in this pool correspond to the OwnerCap
        owner_cap: VecMap<ID, ID>,
        ///The NFTs currently available in this pool correspond to the BorrowCap
        borrow_cap: VecMap<ID, ID>,
        ///NFT currently listed in the market and the number of times listed
        listed: VecMap<ID, u64>,
        /// Number of times NFT is currently immutably borrowed by outside parties
        immutable_borrowed: VecMap<ID, u64>,
        /// NFT is currently mutably borrowed by outside parties
        mutable_borrowed: VecSet<ID>,
        ///NFT is currently being Flashloaned
        flash_loan: VecSet<ID>,
    }

    ///Represents the ownership of NFTs placed in the pool
    struct OwnerCap<phantom Item> has key, store {
        id: UID,
        ///Corresponding pool ID
        safe_id: ID,
        ///Corresponding item ID
        item_id: ID,
    }

    ///listing NFT's Capabilities
    struct TransferCap<phantom Item> has key, store {
        id: UID,
        ///Corresponding ownerCap ID
        owner_id: ID,
        ///Corresponding pool ID
        safe_id: ID,
        ///Corresponding item ID
        item_id: ID,
    }

    ///Borrow NFT's capability
    struct BorrowCap<phantom Item> has key, store {
        id: UID,
        safe_id: ID,
        item_id: ID,
    }

    /// flashloan NFT
    struct FlashLoanReceipt<phantom Item> {
        safe_id: ID,
        item_id: ID,
    }


    struct Borrowed<phantom Item> has key, store {
        id: UID,
        borrow_cap_id: ID,
        safe_id: ID,
        item_id: ID,
        active: bool
    }

    const EOperatorNotAuthWithdrawNFT: u64 = 0;
    const EOwnerCapIllegal: u64 = 1;
    const EItemBeFlashloaning: u64 = 2;
    const EItemIDMismatch: u64 = 3;
    const ESafeIDMismatch: u64 = 4;
    const EItemMutableLease: u64 = 5;
    const EItemMutableAndImmutable: u64 = 6;
    const EItemIDBorrowCapMisMatch: u64 = 7;
    const EBorrowedNoActive: u64 = 8;
    const EItemAlreadyFlashLoaning: u64 = 9;
    const EItemNotFlashLoanWhileMutableBorrowed: u64 = 10;
    const EItemNotExistInTableObject: u64 = 11;

    ///Create a pool
    public fun create<Item: key+store>(ctx: &mut TxContext): SafePool<Item> {
        let self = SafePool<Item> {
            id: object::new(ctx),
            nfts: object_table::new<ID, Item>(ctx),
            nicknames: table::new<String, ID>(ctx),
            owner_cap: vec_map::empty<ID, ID>(),
            borrow_cap: vec_map::empty<ID, ID>(),
            listed: vec_map::empty<ID, u64>(),
            immutable_borrowed: vec_map::empty<ID, u64>(),
            mutable_borrowed: vec_set::empty<ID>(),
            flash_loan: vec_set::empty<ID>(),
        };
        self
    }

    ///Add an NFT to the pool and return OwnerCap  BorrowCap
    public fun add_item<Item: key+store>(
        self: &mut SafePool<Item>,
        item: Item,
        ctx: &mut TxContext
    ): (OwnerCap<Item>, BorrowCap<Item>) {
        let nfts = &mut self.nfts;
        let item_id = object::id(&item);
        //add nft
        object_table::add(nfts, item_id, item);
        let owner_cap = OwnerCap<Item> {
            id: object::new(ctx),
            safe_id: object::id(self),
            item_id,
        };
        let borrow_cap = BorrowCap<Item> {
            id: object::new(ctx),
            safe_id: object::id(self),
            item_id,
        };
        (owner_cap, borrow_cap)
    }

    ///Remove NFT from the pool
    public(friend) fun remove_item<Item: key+store>(
        self: &mut SafePool<Item>,
        owner_cap: &OwnerCap<Item>,
        item_id: ID
    ): Item {
        //1 Check the legality of ownerCap
        let owner_id = object::id(owner_cap);
        assert!(vec_map::contains(&self.owner_cap, &item_id), EOperatorNotAuthWithdrawNFT);

        //remove ownerCap
        let (_, item_owner_id) = vec_map::remove(&mut self.owner_cap, &item_id);
        assert!(item_owner_id == owner_id, EOwnerCapIllegal);

        //remove borrow_cap
        vec_map::remove(&mut self.borrow_cap, &item_id);

        //check flash_loan
        assert!(!vec_set::contains(&self.flash_loan, &item_id), EItemBeFlashloaning);
        //remove mutable borrowed
        if (vec_set::contains(&self.mutable_borrowed, &item_id)) {
            vec_set::remove(&mut self.mutable_borrowed, &item_id);
        };
        //remove immutable borrowed
        if (vec_map::contains(&self.immutable_borrowed, &item_id)) {
            vec_map::remove(&mut self.immutable_borrowed, &item_id);
        };

        //remove transfer list
        if (vec_map::contains(&self.listed, &item_id)) {
            vec_map::remove(&mut self.listed, &item_id);
        };

        let item = object_table::remove<ID, Item>(&mut self.nfts, item_id);

        item
    }

    fun withdraw_nft<Item: key+store>(self: &mut SafePool<Item>, item_id: ID): Item {
        //remove owner_cap
        vec_map::remove(&mut self.owner_cap, &item_id);
        //remove borrow_cap
        vec_map::remove(&mut self.borrow_cap, &item_id);

        //remove mutable borrowed
        if (vec_set::contains(&self.mutable_borrowed, &item_id)) {
            vec_set::remove(&mut self.mutable_borrowed, &item_id);
        };
        //remove immutable borrowed
        if (vec_map::contains(&self.immutable_borrowed, &item_id)) {
            vec_map::remove(&mut self.immutable_borrowed, &item_id);
        };

        //remove transfer list
        if (vec_map::contains(&self.listed, &item_id)) {
            vec_map::remove(&mut self.listed, &item_id);
        };
        //withdraw nft
        let item = object_table::remove<ID, Item>(&mut self.nfts, item_id);

        item
    }

    ///list NFT and be marked listing times
    public fun sell_nft<Item: key+store>(
        self: &mut SafePool<Item>,
        owner_cap: &OwnerCap<Item>,
        item_id: ID,
        ctx: &mut TxContext
    ): TransferCap<Item> {
        //1. Check the legality of OwnerCap
        let safe_id = object::id(self);
        let owner_id = object::id(owner_cap);
        assert!(safe_id == owner_cap.safe_id, ESafeIDMismatch);
        assert!(item_id == owner_cap.item_id, EItemIDMismatch);
        assert!(vec_map::get(&self.owner_cap, &item_id) == &owner_id, EOwnerCapIllegal);

        //2. pakcage transferCap

        let transferCap = TransferCap<Item> {
            id: object::new(ctx),
            owner_id,
            safe_id,
            item_id,
        };
        //3 Marking listing times
        if (!vec_map::contains(&mut self.listed, &item_id)) {
            vec_map::insert(&mut self.listed, item_id, 1)
        }else {
            let listing_num = vec_map::get_mut(&mut self.listed, &item_id);
            *listing_num = *listing_num + 1
        };
        //4. return
        return transferCap
    }


    public fun buy_nft<Item: key+store>(
        self: &mut SafePool<Item>,
        transfer_cap: TransferCap<Item>,
        item_id: ID
    ): Item {
        let safe_id = object::id(self);

        assert!(safe_id == transfer_cap.safe_id, ESafeIDMismatch);
        assert!(item_id == transfer_cap.item_id, EItemIDMismatch);
        assert!(vec_map::get(&self.owner_cap, &item_id) == &transfer_cap.owner_id, EOwnerCapIllegal);

        let TransferCap<Item> {
            id,
            owner_id: _,
            safe_id: _,
            item_id: _,
        } = transfer_cap;

        object::delete(id);

        withdraw_nft(self, item_id)
    }

    public fun unborrow_nft<Item: key+store>(self: &mut SafePool<Item>, borrow_cap: Borrowed<Item>) {
        let Borrowed<Item> {
            id,
            borrow_cap_id: _,
            safe_id: _,
            item_id,
            active,
        } = borrow_cap;

        if (active) {
            vec_set::remove(&mut self.mutable_borrowed, &item_id)
        };

        let immutable_num = vec_map::get_mut(&mut self.immutable_borrowed, &item_id);
        if (*immutable_num > 0) {
            *immutable_num = *immutable_num - 1;
        };

        if (*immutable_num == 0) {
            vec_map::remove(&mut self.immutable_borrowed, &item_id);
        };
        object::delete(id)
    }

    ///borrwing NFT
    /// 1. immutable
    /// 2. mutable
    public fun borrow_nft<Item : key+store>(
        self: &mut SafePool<Item>,
        borrow_cap: &BorrowCap<Item>,
        item_id: ID,
        active: bool,
        ctx: &mut TxContext
    ): Borrowed<Item> {
        let safe_id = object::id(self);
        assert!(safe_id == borrow_cap.safe_id, ESafeIDMismatch);
        assert!(item_id == borrow_cap.item_id, EItemIDMismatch);
        //Check if it has been mutable borrowed
        assert!(!vec_set::contains(&self.mutable_borrowed, &item_id), EItemMutableLease);
        let immutable_num = if (vec_map::contains(&self.immutable_borrowed, &item_id)) {
            let num = *vec_map::get(&self.immutable_borrowed, &item_id);
            num
        }else {
            0
        };
        assert!(!(active && immutable_num > 0), EItemMutableAndImmutable);

        let borrow_cap_id = object::id(borrow_cap);

        assert!(borrow_cap_id == *vec_map::get(&mut self.borrow_cap, &item_id), EItemIDBorrowCapMisMatch);

        if (active) {
            vec_set::insert(&mut self.mutable_borrowed, item_id)
        };

        if (immutable_num > 0) {
            let immutable_num1 = vec_map::get_mut(&mut self.immutable_borrowed, &item_id);
            *immutable_num1 = *immutable_num1 + 1
        };

        let borrowed = Borrowed<Item> {
            id: object::new(ctx),
            borrow_cap_id,
            safe_id,
            item_id,
            active
        };
        return borrowed
    }


    public fun get_nft_mut<Item: key+store>(safe: &mut SafePool<Item>, borrowed: &mut Borrowed<Item>): &mut Item {
        assert!(borrowed.active, EBorrowedNoActive);
        return object_table::borrow_mut(&mut safe.nfts, borrowed.item_id)
    }

    public fun get_nft<Item: key+store>(safe: &mut SafePool<Item>, borrowed: &mut Borrowed<Item>): &Item {
        return object_table::borrow(&mut safe.nfts, borrowed.item_id)
    }


    public fun flash_loan_item<Item: key+store>(
        self: &mut SafePool<Item>, item_id: ID,
    ): (Item, FlashLoanReceipt<Item>) {
        assert!(!vec_set::contains(&self.flash_loan, &item_id), EItemAlreadyFlashLoaning);

        assert!(!vec_set::contains(&self.mutable_borrowed, &item_id), EItemNotFlashLoanWhileMutableBorrowed);

        let items = &mut self.nfts;

        assert!(object_table::contains(items, item_id), EItemNotExistInTableObject);

        vec_set::insert(&mut self.flash_loan, item_id);
        let item = object_table::remove(items, item_id);

        let flash_loan_receipt = FlashLoanReceipt<Item> {
            safe_id: object::id(self),
            item_id: object::id(&item),
        };

        (item, flash_loan_receipt)
    }

    public fun replay_item<Item: key+store>(
        self: &mut SafePool<Item>,
        receipt: FlashLoanReceipt<Item>,
        item: Item,
    ) {
        let FlashLoanReceipt<Item> {
            safe_id,
            item_id,
        } = receipt;

        assert!(safe_id == object::id(self), ESafeIDMismatch);
        assert!(item_id == object::id(&item), EItemIDMismatch);

        vec_set::remove(&mut self.flash_loan, &object::id(&item));
        let nfts = &mut self.nfts;

        object_table::add(nfts, item_id, item)
    }

    public fun destory_transferCap<Item: key+store>(transferCap: TransferCap<Item>) {
        let TransferCap<Item> {
            id,
            owner_id: _,
            safe_id: _,
            item_id: _,
        } = transferCap;
        object::delete(id)
    }

    public fun get_transferCap_item_id<Item: key+store>(transferCap: &TransferCap<Item>): ID {
        return transferCap.item_id
    }

    public fun get_borrowed_item_id<Item: key+store>(borrowed: &Borrowed<Item>): ID {
        borrowed.item_id
    }

    public fun get_ownerCap_item_id<Item: key+store>(ownerCap: &OwnerCap<Item>): ID {
        ownerCap.item_id
    }

    public fun get_borrowCap_item_id<Item: key+store>(borrowCap: &BorrowCap<Item>): ID {
        borrowCap.item_id
    }

    public(friend) fun get_mut_borrowed_uid<Item: key+store>(borrowed: &mut Borrowed<Item>): &mut UID {
        &mut borrowed.id
    }
}




