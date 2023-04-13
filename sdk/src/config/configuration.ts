 import { Connection } from "@mysten/sui.js";

export class NetworkConfiguration {
    constructor(
      public networkName: string,
      public network: Connection,
      public packageObjectId: string,
      public marketObjectId: string,
      public isMainNet = false
    ) {}
  }

const devconnection = new Connection({
    fullnode: 'https://fullnode.devnet.sui.io',
    faucet: 'https://faucet.devnet.sui.io/gas',
});


const testonnection = new Connection({
    fullnode: 'https://fullnode.testnet.sui.io',
    faucet: 'https://faucet.testnet.sui.io/gas',
});



export const DEVNET_CONFIG = new NetworkConfiguration(
    'devnet',
     devconnection,
    '0x401e2d45f4a169b965d57e747afc9ed02ef22a76',
    '0x8d20d6cb64e6e7f6c47f6b7b0037dbb1351b5be0', 
);




