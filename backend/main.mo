import Error "mo:base/Error";
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

actor {
    // Types
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
    };

    // State variables
    private stable var tokenDataEntries : [(Text, TokenData)] = [];
    private var tokenDataMap = HashMap.HashMap<Text, TokenData>(10, Text.equal, Text.hash);

    // Constants
    private let UPDATE_INTERVAL = 5 * 60 * 1000000000; // 5 minutes in nanoseconds
    private let CACHE_DURATION = 15 * 60 * 1000000000; // 15 minutes in nanoseconds

    // Initialize state from stable storage
    system func preupgrade() {
        tokenDataEntries := Iter.toArray(tokenDataMap.entries());
    };

    system func postupgrade() {
        for ((k, v) in tokenDataEntries.vals()) {
            tokenDataMap.put(k, v);
        };
    };

    // Helper function to query DEX volumes
    private func queryDEXVolume(token: Text) : async Float {
        // In a real implementation, this would query various DEXes like ICPSwap, Sonic, etc.
        // For demonstration, returning mock data
        return 100000.0;
    };

    // Helper function to query CEX volumes from CoinGecko
    private func queryCEXVolume(token: Text) : async Float {
        // In a real implementation, this would query CoinGecko API
        // For demonstration, returning mock data
        return 200000.0;
    };

    // Update token data
    private func updateTokenData() : async () {
        let tokens = [
            ("ICP", "Internet Computer"),
            ("CKBTC", "Chain-key Bitcoin"),
            ("SNS1", "Service Nervous System"),
            // Add more IC tokens here
        ];

        for ((symbol, name) in tokens.vals()) {
            try {
                let dexVolume = await queryDEXVolume(symbol);
                let cexVolume = await queryCEXVolume(symbol);
                
                let newData : TokenData = {
                    symbol = symbol;
                    name = name;
                    totalSupply = 1000000; // Mock data
                    decimals = 8;
                    price = 100.0; // Mock data
                    marketCap = 100000000.0; // Mock data
                    fdv = 200000000.0; // Mock data
                    volume24h = dexVolume + cexVolume;
                    dexVolume = dexVolume;
                    cexVolume = cexVolume;
                    priceHistory = [100.0, 101.0, 102.0]; // Mock data
                    lastUpdated = Time.now();
                };

                tokenDataMap.put(symbol, newData);
            } catch (e) {
                Debug.print("Error updating token data for " # symbol);
            };
        };
    };

    // Public query function to get all token data
    public query func getAllTokenData() : async [(Text, TokenData)] {
        Iter.toArray(tokenDataMap.entries())
    };

    // Public query function to get specific token data
    public query func getTokenData(symbol: Text) : async ?TokenData {
        tokenDataMap.get(symbol)
    };

    // Initialize periodic updates
    system func timer(setTimer : Nat64 -> ()) : async () {
        await updateTokenData();
        setTimer(Nat64.fromIntWrap(UPDATE_INTERVAL));
    };

    public func heartbeat() : async Text {
        await updateTokenData();
        return "OK";
    };
}
