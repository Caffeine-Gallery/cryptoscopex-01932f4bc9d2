export const idlFactory = ({ IDL }) => {
  const TokenData = IDL.Record({
    'fdv' : IDL.Float64,
    'dexVolume' : IDL.Float64,
    'decimals' : IDL.Nat8,
    'cexVolume' : IDL.Float64,
    'marketCap' : IDL.Float64,
    'name' : IDL.Text,
    'lastUpdated' : IDL.Int,
    'priceHistory' : IDL.Vec(IDL.Float64),
    'volume24h' : IDL.Float64,
    'totalSupply' : IDL.Nat,
    'price' : IDL.Float64,
    'symbol' : IDL.Text,
  });
  return IDL.Service({
    'getAllTokenData' : IDL.Func(
        [],
        [IDL.Vec(IDL.Tuple(IDL.Text, TokenData))],
        ['query'],
      ),
    'getTokenData' : IDL.Func([IDL.Text], [IDL.Opt(TokenData)], ['query']),
    'heartbeat' : IDL.Func([], [IDL.Text], []),
  });
};
export const init = ({ IDL }) => { return []; };
