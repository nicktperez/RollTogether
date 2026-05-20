import Foundation

struct RealtimeSubscriptionDescriptor: Identifiable, Equatable {
    var id: String { channel }
    var channel: String
    var table: String
    var filter: String?
}

struct SupabaseRealtimeService {
    func messageSubscription(threadID: UUID) -> RealtimeSubscriptionDescriptor {
        RealtimeSubscriptionDescriptor(
            channel: "thread:\(threadID.uuidString):messages",
            table: "messages",
            filter: "thread_id=eq.\(threadID.uuidString)"
        )
    }

    func matchSubscription(userID: UUID) -> [RealtimeSubscriptionDescriptor] {
        [
            RealtimeSubscriptionDescriptor(channel: "user:\(userID.uuidString):group-matches", table: "matches", filter: "group_owner_user_id=eq.\(userID.uuidString)"),
            RealtimeSubscriptionDescriptor(channel: "user:\(userID.uuidString):party-matches", table: "matches", filter: "party_owner_user_id=eq.\(userID.uuidString)")
        ]
    }
}
