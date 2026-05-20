import Foundation

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
    private var socket: URLSessionWebSocketTask?
    private var refCounter = 0
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()

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

    func subscribeToMessages(threadID: UUID, accessToken: String, onMessage: @escaping (RealtimeMessageEvent) -> Void) {
        disconnect()
        let channel = messageSubscription(threadID: threadID).channel
        guard var components = URLComponents(url: SupabaseConfig.url.appending(path: "/realtime/v1/websocket"), resolvingAgainstBaseURL: false) else { return }
        components.scheme = components.scheme == "https" ? "wss" : "ws"
        components.queryItems = [
            URLQueryItem(name: "apikey", value: SupabaseConfig.publishableKey),
            URLQueryItem(name: "vsn", value: "1.0.0")
        ]
        guard let url = components.url else { return }

        let task = URLSession.shared.webSocketTask(with: url)
        socket = task
        task.resume()
        sendJoin(topic: channel, accessToken: accessToken)
        receiveLoop(expectedTopic: channel, onMessage: onMessage)
    }

    func disconnect() {
        socket?.cancel(with: .goingAway, reason: nil)
        socket = nil
    }

    private func sendJoin(topic: String, accessToken: String) {
        let message = PhoenixMessage(
            topic: "realtime:\(topic)",
            event: "phx_join",
            payload: [
                "config": AnyCodable([
                    "broadcast": ["self": false],
                    "presence": ["enabled": false],
                    "private": true
                ]),
                "access_token": AnyCodable(accessToken)
            ],
            ref: nextRef()
        )
        send(message)
    }

    private func receiveLoop(expectedTopic: String, onMessage: @escaping (RealtimeMessageEvent) -> Void) {
        socket?.receive { [weak self] result in
            Task { @MainActor in
                guard let self else { return }
                switch result {
                case let .success(message):
                    self.handle(message, expectedTopic: expectedTopic, onMessage: onMessage)
                    self.receiveLoop(expectedTopic: expectedTopic, onMessage: onMessage)
                case .failure:
                    self.socket = nil
                }
            }
        }
    }

    private func handle(_ message: URLSessionWebSocketTask.Message, expectedTopic: String, onMessage: (RealtimeMessageEvent) -> Void) {
        let data: Data?
        switch message {
        case let .data(value): data = value
        case let .string(value): data = value.data(using: .utf8)
        @unknown default: data = nil
        }
        guard let data else { return }
        guard let envelope = try? decoder.decode(PhoenixEnvelope.self, from: data) else { return }
        guard envelope.topic == "realtime:\(expectedTopic)", envelope.event == "broadcast" else { return }
        guard envelope.payload.event == "message_inserted", let payload = envelope.payload.payload else { return }
        if let event = try? decoder.decode(RealtimeMessageEvent.self, from: payload) {
            onMessage(event)
        }
    }

    private func send(_ message: PhoenixMessage) {
        guard let data = try? encoder.encode(message), let text = String(data: data, encoding: .utf8) else { return }
        socket?.send(.string(text)) { _ in }
    }

    private func nextRef() -> String {
        refCounter += 1
        return "\(refCounter)"
    }
}

private struct PhoenixMessage: Encodable {
    var topic: String
    var event: String
    var payload: [String: AnyCodable]
    var ref: String
}

private struct PhoenixEnvelope: Decodable {
    var topic: String
    var event: String
    var payload: BroadcastEnvelope
}

private struct BroadcastEnvelope: Decodable {
    var event: String?
    var payload: Data?

    private enum CodingKeys: String, CodingKey {
        case event
        case payload
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        event = try? container.decode(String.self, forKey: .event)
        if container.contains(.payload) {
            let nested = try container.superDecoder(forKey: .payload)
            payload = try JSONSerialization.data(withJSONObject: try AnyDecodable(from: nested).value)
        } else {
            payload = nil
        }
    }
}

private struct AnyCodable: Encodable {
    let value: Any

    init(_ value: Any) {
        self.value = value
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch value {
        case let string as String: try container.encode(string)
        case let bool as Bool: try container.encode(bool)
        case let int as Int: try container.encode(int)
        case let double as Double: try container.encode(double)
        case let dict as [String: Any]: try container.encode(dict.mapValues { AnyCodable($0) })
        case let array as [Any]: try container.encode(array.map { AnyCodable($0) })
        default: try container.encodeNil()
        }
    }
}

private struct AnyDecodable: Decodable {
    let value: Any

    init(from decoder: Decoder) throws {
        if let container = try? decoder.singleValueContainer() {
            if let value = try? container.decode(String.self) { self.value = value; return }
            if let value = try? container.decode(Bool.self) { self.value = value; return }
            if let value = try? container.decode(Int.self) { self.value = value; return }
            if let value = try? container.decode(Double.self) { self.value = value; return }
            if container.decodeNil() { self.value = NSNull(); return }
        }
        if var array = try? decoder.unkeyedContainer() {
            var values: [Any] = []
            while !array.isAtEnd {
                values.append(try array.decode(AnyDecodable.self).value)
            }
            self.value = values
            return
        }
        let container = try decoder.container(keyedBy: DynamicCodingKey.self)
        var values: [String: Any] = [:]
        for key in container.allKeys {
            values[key.stringValue] = try container.decode(AnyDecodable.self, forKey: key).value
        }
        self.value = values
    }
}

private struct DynamicCodingKey: CodingKey {
    var stringValue: String
    var intValue: Int?

    init?(stringValue: String) { self.stringValue = stringValue }
    init?(intValue: Int) { self.stringValue = "\(intValue)"; self.intValue = intValue }
}
