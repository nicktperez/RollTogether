import Foundation
import Supabase

struct RealtimeSubscriptionDescriptor: Identifiable, Equatable {
    var id: String { channel }
    var channel: String
    var table: String
    var filter: String?
}

struct RealtimeMessageEvent: Decodable, Equatable {
    var id: UUID
    var threadID: UUID
    var senderUserID: UUID?
    var body: String
    var moderationStatus: String

    enum CodingKeys: String, CodingKey {
        case id
        case threadID = "thread_id"
        case senderUserID = "sender_user_id"
        case body
        case moderationStatus = "moderation_status"
    }
}

@MainActor
final class SupabaseRealtimeService: ObservableObject {
    private let client: Supabase.SupabaseClient
    private var channel: RealtimeChannelV2?
    private var listenerTask: Task<Void, Never>?

    init(
        supabaseURL: URL = SupabaseConfig.url,
        supabaseKey: String = SupabaseConfig.publishableKey
    ) {
        client = Supabase.SupabaseClient(supabaseURL: supabaseURL, supabaseKey: supabaseKey)
    }

    func messageSubscription(threadID: UUID) -> RealtimeSubscriptionDescriptor {
        RealtimeSubscriptionDescriptor(
            channel: "thread:\(threadID.uuidString):messages",
            table: "messages",
            filter: "thread_id=eq.\(threadID.uuidString)"
        )
    }

    func matchSubscription(userID: UUID) -> [RealtimeSubscriptionDescriptor] {
        [
            RealtimeSubscriptionDescriptor(channel: "user:\(userID.uuidString):matches", table: "matches", filter: "group_owner_user_id=eq.\(userID.uuidString)"),
            RealtimeSubscriptionDescriptor(channel: "user:\(userID.uuidString):matches", table: "matches", filter: "party_owner_user_id=eq.\(userID.uuidString)")
        ]
    }

    func subscribeToMessages(threadID: UUID, accessToken: String, onMessage: @escaping @MainActor (RealtimeMessageEvent) -> Void) {
        disconnect()
        let topic = messageSubscription(threadID: threadID).channel

        listenerTask = Task { [client] in
            do {
                await client.realtime.setAuth(accessToken)
                let channel = client.channel(topic) {
                    $0.isPrivate = true
                }
                let stream = channel.broadcastStream(event: "message_inserted")
                try await channel.subscribeWithError()

                await MainActor.run {
                    self.channel = channel
                }

                for await message in stream {
                    guard !Task.isCancelled else { break }
                    guard let event = try? message["payload"]?.decode(as: RealtimeMessageEvent.self) else { continue }
                    await onMessage(event)
                }
            } catch {
                await MainActor.run {
                    self.channel = nil
                }
            }
        }
    }

    func disconnect() {
        listenerTask?.cancel()
        listenerTask = nil

        guard let channel else { return }
        self.channel = nil

        Task { [client, channel] in
            await client.removeChannel(channel)
        }
    }
}
