# Sui SwiftNFT 市场文档

## 一、安装
    1.npm install --save @mysten/sui.js
## 一、连接钱包
    import { JsonRpcProvider } from '@mysten/sui.js';

    1.判断windows.suiWallet是否存在，不存在提示安装suiWallet插件,存在则suiWallet = windows.suiWallet
    2.provider = new JsonRpcProvider('https://gateway.devnet.sui.io:443')连接rpc服务
    3.suiWallet.requestPermissions()连接钱包
    4.suiWallet.hasPermissions()判断钱包是否连接上
    5.suiWallet.getAccounts()获取钱包地址，暂不支持断开连接
## 二、调用API
### 1）展示市场上的NFT
    #参数为固定值(市场的objectID)
    await this.provider.getObject("0x9af7f63ea10cf49b57a6b8da42430156ef60e773")
### 2) 创建collection（create_collection）
    #move 接口
     public entry fun create_collection(
         market: &mut Marketplace, 
         name: string::String,
         description: string::String,
         tags: vector<string::String>,
         logo_imge: String,
         featured_image: String,
         url: String,
         website: String,
         tw: String,
         discord: String,
         fee: u64,
         ctx: &mut TxContext
     ){

    import { JsonRpcProvider,MoveCallTransaction,SuiJsonValue} from '@mysten/sui.js';

    1.点击上架时调用await this.provider.getObject(objectId)，获取object相关信息，参数为NFT的objectID
    2.通过object相关信息构造MoveCallTransaction,例如
    packageID: 0x0f2b24c7001abe89a7eec9fcfe31ebf61fc56e9b
    SharedMarketID: 0x88cfa7431845f2f7da88c84d73ae9a1e590e21b2
    let arg :SuiJsonValue[] = ["0x88cfa7431845f2f7da88c84d73ae9a1e590e21b2", "name","description",["Art"], "logo_imge","featured_image",
    "url","website","tw","discord",200]
    let param: MoveCallTransaction = {
      arguments: arg, 
      function: "create_collection",  
      gasBudget: 3000, 
      module: "market",  
      packageObjectId: "0x0f2b24c7001abe89a7eec9fcfe31ebf61fc56e9b", 
      typeArguments: [], 
    };
    let res = await executeMoveCall(param)
    console.log(res)
### 3) 上架（list）
    ///packageID: 0x84a63fc2856f3ff97ef3a96a2cb57c2237834c4d
    //SharedMarketID: 0x94f6a91d0ac7a699cb62d1d604950a285a5ed3ca
    //collection_id:=""
    //bag_id: """"
    //objectID: ""

     #move代码
     public entry fun list<T: store+key>(collection: &Collection, objects: &mut Bag,item: T,
         amount: u64,ctx: &mut TxContext
    
    import { JsonRpcProvider,MoveCallTransaction,SuiJsonValue} from '@mysten/sui.js';

    1.点击下架时调用await this.provider.getObject(objectId)，获取object相关信息，参数为NFT的objectID
    2.通过object相关信息构造MoveCallTransaction,例如
    //参数:collection_id,bag_id,objectID,上架ID,
    let arg :SuiJsonValue[] = ["0x7f6828da6d441596c3012b992840295ed588b589","0xd102a5144f98dec2eb314cdd8c1ac56dac0f3dd4",
    "0x621be72d8629d02edec57fbde193de4d48b72a23",20000]
    let param: MoveCallTransaction = {
      arguments: arg, #参数
      function: "list",  #调用的function
      gasBudget: 10000, # gaslimit 默认10000即可
      module: "market",   # move模块的名称，这里是market
      packageObjectId: "0x11d913217cba9c928f41a439d8c74ee84a782e3e",  # move模块的ObjectID
      typeArguments: ["0xb3178b9654a56f34ea5b1337191e9ecd288e7eab::meta_nft::MetaNFT"], # 前面获取的NFT Object类型
    };
    let res = await executeMoveCall(param)
    console.log(res)
### 3）购买上架的商品(buy_and_take)
    #move代码
    // public entry fun buy_and_take<T: store+key>(market:  &mut Marketplace,collection: &mut Collection,  objects: &mut Bag,
    //     listing: bag::Item<Listing<T>>,
    //     paid: Coin<SUI>,ctx: &mut TxContext){
    
    import { JsonRpcProvider,MoveCallTransaction,SuiJsonValue,MergeCoinTransaction,SplitCoinTransaction} from '@mysten/sui.js';

    1.点击购买时调用await this.provider.getObject(objectId)，获取object相关信息，参数为NFT的objectID
    2.调用await this.provider.getObject(objectId)获取钱包地址的所有的对象，参数为登录的钱包地址,过滤Type为coin::Coin<0x2::sui::SUI>的token
    2.通过await this.provider.mergeCoin(MergeCoinTransaction)、await this.provider.splitCoin(SplitCoinTransaction)构造一个值为NFT价格的token对象
    3.通过object相关信息构造MoveCallTransaction,例如
    let arg :SuiJsonValue[] = ["0xe1826ea60baf5fb6047ae019ee50e76f3f0b2987", "0x8a98a612a6cc9251ff7fc2e06cd4132d9f3549d4", "0x3131092754d75ca2811c386ba97e3cc6e3cd2187",
    "0x00575618bc4e91735384d0bfaf2b2e8006e23d47","0xdf8754e0a601e24cce349c3090212250a464f352"]
    let param: MoveCallTransaction = {
      arguments: arg, # suiJson类型的参数，第一个是Marketplace的ID(固定值)，第二个是list的ID(bag的子Id)，第三个是bag的ID，第四个是coin的对象
      function: "buy_and_take",  # move函数的名称,这里是list
      gasBudget: 10000, # gaslimit 默认10000即可
      module: "market",  # move模块的名称，这里是market
      packageObjectId: "0x249b70fcdaf9c9c3fa6db2c5110fce04acca4ab1", # move模块的ObjectID
      typeArguments: ["0xd3c48b1d8d5c0d0022dfccc79d4af501c5918991::GoblinSuiWarriorNFT::GoblinSuiWarriorNFT"], # 前面获取的NFT Object类型
    }
    let res = await this.suiWallet.executeMoveCall(param)
### 4) 下架商品()
    #move代码
     ////packageID: 0x0fba00837e332cd60a55712db170624911ad1e89
    //SharedMarketID: 0xe1826ea60baf5fb6047ae019ee50e76f3f0b2987

    //collection_id:=""0x8a98a612a6cc9251ff7fc2e06cd4132d9f3549d4""
    //bag_id: """0x3131092754d75ca2811c386ba97e3cc6e3cd2187"""
    //listing_id ""0x06c2e7b1b8e098a65da69c279d4413d47099c8e2""
    // public entry fun delist<T: key + store>(
    //   collection:  &Collection, 
    //   objects: &mut Bag,
    //   listing: bag::Item<Listing<T>>,
    //   ctx: &mut TxContext){

    import { JsonRpcProvider,MoveCallTransaction,SuiJsonValue} from '@mysten/sui.js';

    1.点击下架时调用await this.provider.getObject(objectId)，获取object相关信息，参数为NFT的objectID
    2.通过object相关信息构造MoveCallTransaction,例如

       let arg :SuiJsonValue = ["0x8a98a612a6cc9251ff7fc2e06cd4132d9f3549d4", "0x3131092754d75ca2811c386ba97e3cc6e3cd2187", "0x00575618bc4e91735384d0bfaf2b2e8006e23d47"]
     let param: MoveCallTransaction = {
      arguments: arg, 
      function: "delist_take",  
      gasBudget: 3000, 
      module: "market",  
      packageObjectId: "0x0fba00837e332cd60a55712db170624911ad1e89", 
      typeArguments: ["0x2::devnet_nft::DevNetNFT"], 
    };
    let res = await executeMoveCall(param)
    console.log(res)
### 5) 调整价格(adjust)
    // public entry fun adjust_price<T: store+key>(
    //     collection:  &mut Collection,
    //     objects: &mut Bag,
    //     listing: bag::Item<Listing<T>>,
    //     amount: u64,
    //     ctx: &mut TxContext){

    import { JsonRpcProvider,MoveCallTransaction,SuiJsonValue} from '@mysten/sui.js';

    1.点击出价时调用await this.provider.getObject(objectId)，获取object相关信息，参数为NFT的objectID
    2.通过await this.provider.mergeCoin(MergeCoinTransaction)、await this.provider.splitCoin(SplitCoinTransaction)构造一个值为NFT价格的Coin对象
    3.通过object相关信息构造MoveCallTransaction,例如
    let arg :SuiJsonValue = ["0x8a98a612a6cc9251ff7fc2e06cd4132d9f3549d4", "0x3131092754d75ca2811c386ba97e3cc6e3cd2187", "0x00575618bc4e91735384d0bfaf2b2e8006e23d47",4000]
    let param: MoveCallTransaction = {
      arguments: arg, # suiJson类型的参数，第一个是想购买NFT的ID，第二个是构造的那个Coin对象，第三个是出价有效的epoch数(天数)
      function: "adjust_price",  # move函数的名称,这里是adjust_price
      gasBudget: 10000, # gaslimit 默认10000即可
      module: "market",  # move模块的名称，这里是market
      packageObjectId: "0x249b70fcdaf9c9c3fa6db2c5110fce04acca4ab1", # move模块的ObjectID
      typeArguments: ["0xd3c48b1d8d5c0d0022dfccc79d4af501c5918991::GoblinSuiWarriorNFT::GoblinSuiWarriorNFT"], # 前面获取的NFT Object类型
    }
    let res = await this.suiWallet.executeMoveCall(param)
