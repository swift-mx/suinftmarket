import { Connection } from "@mysten/sui.js";
export declare class NetworkConfiguration {
    networkName: string;
    network: Connection;
    packageObjectId: string;
    marketObjectId: string;
    isMainNet: boolean;
    constructor(networkName: string, network: Connection, packageObjectId: string, marketObjectId: string, isMainNet?: boolean);
}
export declare const DEVNET_CONFIG: NetworkConfiguration;
//# sourceMappingURL=configuration.d.ts.map