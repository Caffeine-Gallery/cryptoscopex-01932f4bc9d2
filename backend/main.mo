import Nat8 "mo:base/Nat8";

import Array "mo:base/Array";
import Buffer "mo:base/Buffer";
import Debug "mo:base/Debug";
import Float "mo:base/Float";
import Hash "mo:base/Hash";
import HashMap "mo:base/HashMap";
import Int "mo:base/Int";
import Iter "mo:base/Iter";
import Nat "mo:base/Nat";
import Nat64 "mo:base/Nat64";
import Option "mo:base/Option";
import Principal "mo:base/Principal";
import Text "mo:base/Text";
import Time "mo:base/Time";
import Timer "mo:base/Timer";
import Error "mo:base/Error";
import IC "mo:ic";

actor {
    type TokenData = {
        symbol: Text;
        name: Text;
        totalSupply: Nat;
        decimals: Nat8;
        price: Float;
        marketCap: Float;
        fdv: Float;
        volume24h: Float;
        dexVolume: Float;
        cexVolume: Float;
        priceHistory: [Float];
        lastUpdated: Int;
        canisterId: ?Text;
        standard: Text;
    };

    // DEX interfaces
    type ICPSwapInterface = actor {
        getTokenPrice: shared (Text) -> async Float;
        get24hVolume: shared (Text) -> async Float;
    };

    type SonicInterface = actor {
        getPrice: shared (Text) -> async Float;
        getDailyVolume: shared (Text) -> async Float;
    };

    private let IC_TOKENS = [
        // Main IC tokens
        {symbol = "ICP"; name = "Internet Computer"; canisterId = null; standard = "Native"},
        {symbol = "ckBTC"; name = "Chain-key Bitcoin"; canisterId = ?"mxzaz-hqaaa-aaaar-qaada-cai"; standard = "ICRC1"},
        {symbol = "ckETH"; name = "Chain-key Ethereum"; canisterId = ?"ss2fx-dyaaa-aaaar-qacoq-cai"; standard = "ICRC1"},
        
        // SNS tokens
        {symbol = "KINIC"; name = "KINIC"; canisterId = ?"73mez-iiaaa-aaaaq-aaasq-cai"; standard = "SNS"},
        {symbol = "HOT"; name = "Hot or Not"; canisterId = ?"6rdgd-kyaaa-aaaaq-aaavq-cai"; standard = "SNS"},
        {symbol = "BOOM"; name = "BoomDAO"; canisterId = ?"vtrom-gqaaa-aaaaq-aabia-cai"; standard = "SNS"},
        
        // Other ICRC-1 tokens
        {symbol = "CHAT"; name = "CHAT Token"; canisterId = ?"2ouva-viaaa-aaaaq-aaamq-cai"; standard = "ICRC1"},
        {symbol = "MOD"; name = "Modclub"; canisterId = ?"xsi2v-cyaaa-aaaaq-aabfq-cai"; standard = "ICRC1"},
        {symbol = "CAT"; name = "Catalyze"; canisterId = ?"uf2wh-taaaa-aaaaq-aabna-cai"; standard = "ICRC1"}
    ];

    private stable var tokenDataEntries : [(Text, TokenData)] = [];
    private var tokenDataMap = HashMap.HashMap<Text, TokenData>(20, Text.equal, Text.hash);

    private let UPDATE_INTERVAL = 5 * 60 * 1000000000; // 5 minutes
    private let CACHE_DURATION = 15 * 60 * 1000000000;

    private let ICPSWAP_CANISTER = "qz7gu-giaaa-aaaaf-qaaka-cai";
    private let SONIC_CANISTER = "3xwpq-ziaaa-aaaah-qcn4a-cai";
    private let ICLIGHTHOUSE_CANISTER = "4g3km-nyaaa-aaaah-qcyka-cai";

    private let ic : IC.Service = actor("aaaaa-aa");

    system func preupgrade() {
        tokenDataEntries := Iter.toArray(tokenDataMap.entries());
    };

    system func postupgrade() {
        for ((k, v) in tokenDataEntries.vals()) {
            tokenDataMap.put(k, v);
        };
    };

    private func queryDEXVolume(token: Text) : async Float {
        try {
            let icpswap : ICPSwapInterface = actor(ICPSWAP_CANISTER);
            let sonic : SonicInterface = actor(SONIC_CANISTER);

            let icpswapVolume = await icpswap.get24hVolume(token);
            let sonicVolume = await sonic.getDailyVolume(token);

            return icpswapVolume + sonicVolume;
        } catch (e) {
            Debug.print("Error querying DEX volume: " # Error.message(e));
            return 0.0;
        };
    };

    private func queryCEXVolume(token: Text) : async Float {
        try {
            let request : IC.HttpRequestArgs = {
                url = "https://api.coingecko.com/api/v3/simple/token_price/" # token;
                max_response_bytes = ?2048;
                headers = [{ name = "Accept"; value = "application/json" }];
                body = null;
                method = #get;
                transform = null;
            };

            let response = await ic.http_request(request);
            
            // Parse response and extract volume
            // Note: This is simplified, you'd need to properly parse the JSON response
            return 0.0; // Placeholder
        } catch (e) {
            Debug.print("Error querying CEX volume: " # Error.message(e));
            return 0.0;
        };
    };

    private func updateTokenData() : async () {
        for (tokenInfo in IC_TOKENS.vals()) {
            try {
                let dexVolume = await queryDEXVolume(tokenInfo.symbol);
                let cexVolume = await queryCEXVolume(tokenInfo.symbol);
                
                // Query additional data based on token standard
                var totalSupply = 0;
                var price = 0.0;
                
                switch (tokenInfo.standard) {
                    case "ICRC1" {
                        // Query ICRC1 token data
                    };
                    case "SNS" {
                        // Query SNS token data
                    };
                    case _ {
                        // Handle other token types
                    };
                };

                let newData : TokenData = {
                    symbol = tokenInfo.symbol;
                    name = tokenInfo.name;
                    totalSupply = totalSupply;
                    decimals = 8;
                    price = price;
                    marketCap = Float.fromInt(totalSupply) * price;
                    fdv = price * Float.fromInt(totalSupply);
                    volume24h = dexVolume + cexVolume;
                    dexVolume = dexVolume;
                    cexVolume = cexVolume;
                    priceHistory = []; // Would need to implement price history tracking
                    lastUpdated = Time.now();
                    canisterId = tokenInfo.canisterId;
                    standard = tokenInfo.standard;
                };

                tokenDataMap.put(tokenInfo.symbol, newData);
            } catch (e) {
                Debug.print("Error updating token data for " # tokenInfo.symbol # ": " # Error.message(e));
            };
        };
    };

    public query func getAllTokenData() : async [(Text, TokenData)] {
        Iter.toArray(tokenDataMap.entries())
    };

    public query func getTokenData(symbol: Text) : async ?TokenData {
        tokenDataMap.get(symbol)
    };

    system func timer(setTimer : Nat64 -> ()) : async () {
        await updateTokenData();
        setTimer(Nat64.fromIntWrap(UPDATE_INTERVAL));
    };

    public func heartbeat() : async Text {
        await updateTokenData();
        return "OK";
    };
}
