import { JsonRpcProvider, TxnDataSerializer } from '@mysten/sui.js';
import { NetworkConfiguration } from '../config/configuration';
import { MarketMoudle } from '../modules/MarketMoudle/MarketMoudle';
export declare class SDK {
    protected _jsonRpcProvider: JsonRpcProvider;
    protected _networkConfiguration: NetworkConfiguration;
    protected _serializer: TxnDataSerializer;
    protected _market: MarketMoudle;
    get jsonRpcProvider(): JsonRpcProvider;
    get Market(): MarketMoudle;
    get networkOptions(): NetworkConfiguration;
    get serializer(): TxnDataSerializer;
    constructor(networkConfiguration: NetworkConfiguration);
}
//# sourceMappingURL=sdk.d.ts.map