import type { Principal } from '@dfinity/principal';
import type { ActorMethod } from '@dfinity/agent';
import type { IDL } from '@dfinity/candid';

export interface TokenData {
  'fdv' : number,
  'dexVolume' : number,
  'decimals' : number,
  'cexVolume' : number,
  'marketCap' : number,
  'name' : string,
  'lastUpdated' : bigint,
  'priceHistory' : Array<number>,
  'volume24h' : number,
  'totalSupply' : bigint,
  'price' : number,
  'symbol' : string,
}
export interface _SERVICE {
  'getAllTokenData' : ActorMethod<[], Array<[string, TokenData]>>,
  'getTokenData' : ActorMethod<[string], [] | [TokenData]>,
  'heartbeat' : ActorMethod<[], string>,
}
export declare const idlFactory: IDL.InterfaceFactory;
export declare const init: (args: { IDL: typeof IDL }) => IDL.Type[];
