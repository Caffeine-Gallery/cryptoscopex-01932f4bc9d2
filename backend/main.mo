import Text "mo:base/Text";

actor {
    // Simple heartbeat function to check if the canister is running
    public query func heartbeat() : async Text {
        return "OK";
    };
}
