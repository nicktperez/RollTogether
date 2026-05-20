import Foundation

struct SupabaseSession: Codable, Equatable {
    struct User: Codable, Equatable {
        var id: UUID
        var email: String?
    }

    var accessToken: String
    var refreshToken: String
    var user: User

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case user
    }
}

struct SupabaseProfilePayload: Codable, Equatable {
    var id: UUID
    var displayName: String
    var handle: String?
    var bio: String
    var location: String
    var latitude: Double?
    var longitude: Double?
    var experience: String
    var preferredMode: String
    var favoriteRole: String
    var safetyNote: String

    enum CodingKeys: String, CodingKey {
        case id
        case displayName = "display_name"
        case handle
        case bio
        case location
        case latitude
        case longitude
        case experience
        case preferredMode = "preferred_mode"
        case favoriteRole = "favorite_role"
        case safetyNote = "safety_note"
    }
}

struct SupabaseListingPayload: Codable, Identifiable, Equatable {
    var id: UUID?
    var ownerUserID: UUID
    var listingType: String
    var name: String
    var mode: String
    var location: String
    var latitude: Double?
    var longitude: Double?
    var openSlots: Int
    var partySize: Int
    var campaignStyle: String
    var tableExperience: String
    var desiredExperience: String
    var lookingForPartySize: String
    var characterVibe: String
    var schedule: String
    var about: String
    var contact: String
    var isActive: Bool

    enum CodingKeys: String, CodingKey {
        case id
        case ownerUserID = "owner_user_id"
        case listingType = "listing_type"
        case name
        case mode
        case location
        case latitude
        case longitude
        case openSlots = "open_slots"
        case partySize = "party_size"
        case campaignStyle = "campaign_style"
        case tableExperience = "table_experience"
        case desiredExperience = "desired_experience"
        case lookingForPartySize = "looking_for_party_size"
        case characterVibe = "character_vibe"
        case schedule
        case about
        case contact
        case isActive = "is_active"
    }
}

struct SupabaseRolePayload: Codable, Equatable {
    var listingID: UUID
    var role: String
    var roleKind: String

    enum CodingKeys: String, CodingKey {
        case listingID = "listing_id"
        case role
        case roleKind = "role_kind"
    }
}

struct SupabaseSwipePayload: Codable, Equatable {
    var swiperUserID: UUID
    var ownerListingID: UUID
    var targetListingID: UUID
    var choice: String
    var context: String

    enum CodingKeys: String, CodingKey {
        case swiperUserID = "swiper_user_id"
        case ownerListingID = "owner_listing_id"
        case targetListingID = "target_listing_id"
        case choice
        case context
    }
}

struct SupabaseMatchPayload: Codable, Identifiable, Equatable {
    var id: UUID?
    var groupListingID: UUID
    var partyListingID: UUID
    var groupOwnerUserID: UUID
    var partyOwnerUserID: UUID
    var score: Int
    var initiatedBy: UUID?
    var status: String

    enum CodingKeys: String, CodingKey {
        case id
        case groupListingID = "group_listing_id"
        case partyListingID = "party_listing_id"
        case groupOwnerUserID = "group_owner_user_id"
        case partyOwnerUserID = "party_owner_user_id"
        case score
        case initiatedBy = "initiated_by"
        case status
    }
}

struct SupabaseThreadPayload: Codable, Identifiable, Equatable {
    var id: UUID?
    var matchID: UUID
    var lastMessagePreview: String

    enum CodingKeys: String, CodingKey {
        case id
        case matchID = "match_id"
        case lastMessagePreview = "last_message_preview"
    }
}

struct SupabaseMessagePayload: Codable, Identifiable, Equatable {
    var id: UUID?
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

struct SupabaseReportPayload: Codable, Equatable {
    var reporterUserID: UUID
    var subject: String
    var targetListingID: UUID?
    var targetMessageID: UUID?
    var reason: String
    var details: String

    enum CodingKeys: String, CodingKey {
        case reporterUserID = "reporter_user_id"
        case subject
        case targetListingID = "target_listing_id"
        case targetMessageID = "target_message_id"
        case reason
        case details
    }
}

struct SupabaseBlockPayload: Codable, Equatable {
    var blockerUserID: UUID
    var blockedListingID: UUID?
    var reason: String

    enum CodingKeys: String, CodingKey {
        case blockerUserID = "blocker_user_id"
        case blockedListingID = "blocked_listing_id"
        case reason
    }
}

struct SupabasePushTokenPayload: Codable, Equatable {
    var userID: UUID
    var platform: String
    var token: String
    var environment: String

    enum CodingKeys: String, CodingKey {
        case userID = "user_id"
        case platform
        case token
        case environment
    }
}

struct SupabaseNearbyListingID: Codable, Equatable {
    var id: UUID
    var distanceMiles: Double

    enum CodingKeys: String, CodingKey {
        case id
        case distanceMiles = "distance_miles"
    }
}

struct SupabaseMatchThreadPayload: Codable, Equatable {
    var matchID: UUID
    var threadID: UUID

    enum CodingKeys: String, CodingKey {
        case matchID = "match_id"
        case threadID = "thread_id"
    }
}

struct SupabaseModerationEventPayload: Codable, Equatable {
    var userID: UUID
    var subject: String
    var targetListingID: UUID?
    var targetMessageID: UUID?
    var status: String
    var reason: String

    enum CodingKeys: String, CodingKey {
        case userID = "user_id"
        case subject
        case targetListingID = "target_listing_id"
        case targetMessageID = "target_message_id"
        case status
        case reason
    }
}

enum SupabaseClientError: LocalizedError {
    case invalidResponse
    case requestFailed(Int, String)
    case missingSession

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Supabase returned an invalid response."
        case let .requestFailed(status, body):
            return "Supabase request failed with HTTP \(status): \(body)"
        case .missingSession:
            return "A signed-in Supabase session is required."
        }
    }
}

final class SupabaseClient {
    private let baseURL: URL
    private let publishableKey: String
    private let session: URLSession
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()

    init(
        baseURL: URL = SupabaseConfig.url,
        publishableKey: String = SupabaseConfig.publishableKey,
        session: URLSession = .shared
    ) {
        self.baseURL = baseURL
        self.publishableKey = publishableKey
        self.session = session
    }

    func checkConnection() async -> Bool {
        do {
            var request = URLRequest(url: baseURL.appending(path: "/auth/v1/settings"))
            request.httpMethod = "GET"
            applyBaseHeaders(to: &request)
            let (_, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse else { return false }
            return (200..<500).contains(http.statusCode)
        } catch {
            return false
        }
    }

    func signUp(email: String, password: String, displayName: String) async throws -> SupabaseSession {
        try await authRequest(
            path: "/auth/v1/signup",
            body: AuthSignUpRequest(email: email, password: password, data: ["display_name": displayName])
        )
    }

    func signIn(email: String, password: String) async throws -> SupabaseSession {
        try await authRequest(path: "/auth/v1/token?grant_type=password", body: AuthEmailPasswordRequest(email: email, password: password))
    }

    func signInWithApple(idToken: String, nonce: String, fullName: String?) async throws -> SupabaseSession {
        try await authRequest(
            path: "/auth/v1/token?grant_type=id_token",
            body: AuthIDTokenRequest(provider: "apple", idToken: idToken, nonce: nonce, data: fullName.map { ["full_name": $0] })
        )
    }

    func refreshSession(refreshToken: String) async throws -> SupabaseSession {
        try await authRequest(path: "/auth/v1/token?grant_type=refresh_token", body: AuthRefreshRequest(refreshToken: refreshToken))
    }

    func recoverPassword(email: String) async throws {
        let _: EmptyResponse = try await authRequest(path: "/auth/v1/recover", body: AuthRecoverRequest(email: email))
    }

    func fetchProfile(accessToken: String) async throws -> SupabaseProfilePayload {
        var components = URLComponents(url: baseURL.appending(path: "/rest/v1/profiles"), resolvingAgainstBaseURL: false)!
        components.queryItems = [URLQueryItem(name: "select", value: "*"), URLQueryItem(name: "limit", value: "1")]
        let profiles: [SupabaseProfilePayload] = try await restRequest(url: components.url!, accessToken: accessToken)
        guard let profile = profiles.first else { throw SupabaseClientError.invalidResponse }
        return profile
    }

    func updateProfile(_ profile: SupabaseProfilePayload, accessToken: String) async throws -> SupabaseProfilePayload {
        var components = URLComponents(url: baseURL.appending(path: "/rest/v1/profiles"), resolvingAgainstBaseURL: false)!
        components.queryItems = [URLQueryItem(name: "id", value: "eq.\(profile.id.uuidString)")]
        let updated: [SupabaseProfilePayload] = try await restRequest(
            url: components.url!,
            method: "PATCH",
            accessToken: accessToken,
            body: profile,
            prefer: "return=representation"
        )
        guard let first = updated.first else { throw SupabaseClientError.invalidResponse }
        return first
    }

    func fetchListings(accessToken: String, listingType: String? = nil) async throws -> [SupabaseListingPayload] {
        var components = URLComponents(url: baseURL.appending(path: "/rest/v1/listings"), resolvingAgainstBaseURL: false)!
        var queryItems = [
            URLQueryItem(name: "select", value: "*"),
            URLQueryItem(name: "is_active", value: "eq.true"),
            URLQueryItem(name: "order", value: "created_at.desc")
        ]
        if let listingType {
            queryItems.append(URLQueryItem(name: "listing_type", value: "eq.\(listingType)"))
        }
        components.queryItems = queryItems
        return try await restRequest(url: components.url!, accessToken: accessToken)
    }

    func createListing(_ listing: SupabaseListingPayload, accessToken: String) async throws -> SupabaseListingPayload {
        let created: [SupabaseListingPayload] = try await restRequest(
            url: baseURL.appending(path: "/rest/v1/listings"),
            method: "POST",
            accessToken: accessToken,
            body: listing,
            prefer: "return=representation"
        )
        guard let first = created.first else { throw SupabaseClientError.invalidResponse }
        return first
    }

    func createRoles(_ roles: [SupabaseRolePayload], accessToken: String) async throws {
        guard !roles.isEmpty else { return }
        let _: EmptyResponse = try await restRequest(
            url: baseURL.appending(path: "/rest/v1/listing_roles"),
            method: "POST",
            accessToken: accessToken,
            body: roles,
            prefer: "return=minimal"
        )
    }

    func createSwipe(_ swipe: SupabaseSwipePayload, accessToken: String) async throws {
        let _: EmptyResponse = try await restRequest(
            url: baseURL.appending(path: "/rest/v1/swipes"),
            method: "POST",
            accessToken: accessToken,
            body: swipe,
            prefer: "return=minimal,resolution=ignore-duplicates"
        )
    }

    func createMatch(_ match: SupabaseMatchPayload, accessToken: String) async throws -> SupabaseMatchPayload {
        let created: [SupabaseMatchPayload] = try await restRequest(
            url: baseURL.appending(path: "/rest/v1/matches"),
            method: "POST",
            accessToken: accessToken,
            body: match,
            prefer: "return=representation,resolution=ignore-duplicates"
        )
        guard let first = created.first else { throw SupabaseClientError.invalidResponse }
        return first
    }

    func createThread(_ thread: SupabaseThreadPayload, accessToken: String) async throws -> SupabaseThreadPayload {
        let created: [SupabaseThreadPayload] = try await restRequest(
            url: baseURL.appending(path: "/rest/v1/message_threads"),
            method: "POST",
            accessToken: accessToken,
            body: thread,
            prefer: "return=representation,resolution=ignore-duplicates"
        )
        guard let first = created.first else { throw SupabaseClientError.invalidResponse }
        return first
    }

    func createMatchThread(groupListingID: UUID, partyListingID: UUID, score: Int, accessToken: String) async throws -> SupabaseMatchThreadPayload {
        try await functionRequest(
            name: "create-match-thread",
            accessToken: accessToken,
            body: [
                "group_listing_id": groupListingID.uuidString,
                "party_listing_id": partyListingID.uuidString,
                "score": "\(score)"
            ]
        )
    }

    func fetchThreads(accessToken: String) async throws -> [SupabaseThreadPayload] {
        var components = URLComponents(url: baseURL.appending(path: "/rest/v1/message_threads"), resolvingAgainstBaseURL: false)!
        components.queryItems = [URLQueryItem(name: "select", value: "*"), URLQueryItem(name: "order", value: "updated_at.desc")]
        return try await restRequest(url: components.url!, accessToken: accessToken)
    }

    func fetchMessages(threadID: UUID, accessToken: String) async throws -> [SupabaseMessagePayload] {
        var components = URLComponents(url: baseURL.appending(path: "/rest/v1/messages"), resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "select", value: "*"),
            URLQueryItem(name: "thread_id", value: "eq.\(threadID.uuidString)"),
            URLQueryItem(name: "order", value: "created_at.asc")
        ]
        return try await restRequest(url: components.url!, accessToken: accessToken)
    }

    func createMessage(_ message: SupabaseMessagePayload, accessToken: String) async throws -> SupabaseMessagePayload {
        let created: [SupabaseMessagePayload] = try await restRequest(
            url: baseURL.appending(path: "/rest/v1/messages"),
            method: "POST",
            accessToken: accessToken,
            body: message,
            prefer: "return=representation"
        )
        guard let first = created.first else { throw SupabaseClientError.invalidResponse }
        return first
    }

    func createReport(_ report: SupabaseReportPayload, accessToken: String) async throws {
        let _: EmptyResponse = try await restRequest(
            url: baseURL.appending(path: "/rest/v1/reports"),
            method: "POST",
            accessToken: accessToken,
            body: report,
            prefer: "return=minimal"
        )
    }

    func createBlock(_ block: SupabaseBlockPayload, accessToken: String) async throws {
        let _: EmptyResponse = try await restRequest(
            url: baseURL.appending(path: "/rest/v1/blocks"),
            method: "POST",
            accessToken: accessToken,
            body: block,
            prefer: "return=minimal"
        )
    }

    func createModerationEvent(_ event: SupabaseModerationEventPayload, accessToken: String) async throws {
        let _: EmptyResponse = try await restRequest(
            url: baseURL.appending(path: "/rest/v1/moderation_events"),
            method: "POST",
            accessToken: accessToken,
            body: event,
            prefer: "return=minimal"
        )
    }

    func upsertPushToken(_ token: SupabasePushTokenPayload, accessToken: String) async throws {
        var components = URLComponents(url: baseURL.appending(path: "/rest/v1/push_tokens"), resolvingAgainstBaseURL: false)!
        components.queryItems = [URLQueryItem(name: "on_conflict", value: "platform,token")]
        let _: EmptyResponse = try await restRequest(
            url: components.url!,
            method: "POST",
            accessToken: accessToken,
            body: token,
            prefer: "return=minimal,resolution=merge-duplicates"
        )
    }

    func nearbyListings(type: String, latitude: Double, longitude: Double, miles: Double, accessToken: String) async throws -> [SupabaseNearbyListingID] {
        let body: [String: AnyEncodable] = [
            "search_listing_type": AnyEncodable(type),
            "origin_lat": AnyEncodable(latitude),
            "origin_lon": AnyEncodable(longitude),
            "max_miles": AnyEncodable(miles)
        ]
        return try await restRequest(
            url: baseURL.appending(path: "/rest/v1/rpc/search_listings_nearby"),
            method: "POST",
            accessToken: accessToken,
            body: body
        )
    }

    func deleteAccount(reason: String, accessToken: String) async throws {
        let _: EmptyResponse = try await functionRequest(name: "delete-account", accessToken: accessToken, body: ["reason": reason])
    }

    func inspectPushQueue(accessToken: String) async throws {
        let _: EmptyResponse = try await functionRequest(name: "send-push-notifications", accessToken: accessToken, body: ["dryRun": true])
    }

    private func authRequest<Response: Decodable>(path: String, body: Encodable) async throws -> Response {
        var request = URLRequest(url: baseURL.appending(path: path))
        request.httpMethod = "POST"
        applyBaseHeaders(to: &request)
        request.httpBody = try encoder.encode(AnyEncodable(body))

        let data = try await checkedData(for: request)
        return try decode(Response.self, from: data)
    }

    private func functionRequest<Response: Decodable>(name: String, accessToken: String, body: Encodable) async throws -> Response {
        var request = URLRequest(url: baseURL.appending(path: "/functions/v1/\(name)"))
        request.httpMethod = "POST"
        applyBaseHeaders(to: &request)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.httpBody = try encoder.encode(AnyEncodable(body))
        let data = try await checkedData(for: request)
        return try decode(Response.self, from: data)
    }

    private func restRequest<Response: Decodable>(
        url: URL,
        method: String = "GET",
        accessToken: String,
        body: Encodable? = nil,
        prefer: String? = nil
    ) async throws -> Response {
        var request = URLRequest(url: url)
        request.httpMethod = method
        applyBaseHeaders(to: &request)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        if let prefer {
            request.setValue(prefer, forHTTPHeaderField: "Prefer")
        }
        if let body {
            request.httpBody = try encoder.encode(AnyEncodable(body))
        }

        let data = try await checkedData(for: request)
        return try decode(Response.self, from: data)
    }

    private func checkedData(for request: URLRequest) async throws -> Data {
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw SupabaseClientError.invalidResponse }
        guard (200..<300).contains(http.statusCode) else {
            throw SupabaseClientError.requestFailed(http.statusCode, String(data: data, encoding: .utf8) ?? "")
        }
        return data
    }

    private func decode<Response: Decodable>(_ type: Response.Type, from data: Data) throws -> Response {
        if type == EmptyResponse.self, data.isEmpty {
            return EmptyResponse() as! Response
        }
        return try decoder.decode(Response.self, from: data)
    }

    private func applyBaseHeaders(to request: inout URLRequest) {
        request.setValue(publishableKey, forHTTPHeaderField: "apikey")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
    }
}

struct EmptyResponse: Codable {}

private struct AuthEmailPasswordRequest: Encodable {
    var email: String
    var password: String
}

private struct AuthSignUpRequest: Encodable {
    var email: String
    var password: String
    var data: [String: String]
}

private struct AuthRecoverRequest: Encodable {
    var email: String
}

private struct AuthRefreshRequest: Encodable {
    var refreshToken: String

    enum CodingKeys: String, CodingKey {
        case refreshToken = "refresh_token"
    }
}

private struct AuthIDTokenRequest: Encodable {
    var provider: String
    var idToken: String
    var nonce: String
    var data: [String: String]?

    enum CodingKeys: String, CodingKey {
        case provider
        case idToken = "id_token"
        case nonce
        case data
    }
}

struct AnyEncodable: Encodable {
    private let encodeClosure: (Encoder) throws -> Void

    init(_ wrapped: Encodable) {
        encodeClosure = wrapped.encode(to:)
    }

    func encode(to encoder: Encoder) throws {
        try encodeClosure(encoder)
    }
}
