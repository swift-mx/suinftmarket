import { JsonRpcProvider, RpcTxnDataSerializer, TxnDataSerializer,devnetConnection} from '@mysten/sui.js';
import {NetworkConfiguration} from '../config/configuration';
import {MarketMoudle} from '../modules/MarketMoudle/MarketMoudle'



export class SDK{
    protected _jsonRpcProvider: JsonRpcProvider;
    protected _networkConfiguration: NetworkConfiguration;
    protected _serializer: TxnDataSerializer;
    protected _market: MarketMoudle

    get jsonRpcProvider() {
        return this._jsonRpcProvider;
    }
    get Market() {
        return this._market;
    }

    get networkOptions() {
        return this._networkConfiguration;
    }

    get serializer() {
        return this._serializer;
    }

    constructor(networkConfiguration:NetworkConfiguration) {
      
        this._jsonRpcProvider = new JsonRpcProvider(networkConfiguration.network)
        this._serializer = new RpcTxnDataSerializer(this._jsonRpcProvider.connection.fullnode, 
            this._jsonRpcProvider.options.skipDataValidation!)
        this._networkConfiguration = networkConfiguration;
        this._market = new MarketMoudle(this);
    }

}