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

struct SupabaseProfilePayload: Codable {
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

struct SupabaseListingPayload: Codable, Identifiable {
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

    func signUp(email: String, password: String) async throws -> SupabaseSession {
        try await authRequest(path: "/auth/v1/signup", body: ["email": email, "password": password])
    }

    func signIn(email: String, password: String) async throws -> SupabaseSession {
        try await authRequest(path: "/auth/v1/token?grant_type=password", body: ["email": email, "password": password])
    }

    func fetchProfile(accessToken: String) async throws -> SupabaseProfilePayload {
        var components = URLComponents(url: baseURL.appending(path: "/rest/v1/profiles"), resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "select", value: "*"),
            URLQueryItem(name: "limit", value: "1")
        ]
        let profiles: [SupabaseProfilePayload] = try await restRequest(url: components.url!, accessToken: accessToken)
        guard let profile = profiles.first else { throw SupabaseClientError.invalidResponse }
        return profile
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

    private func authRequest(path: String, body: [String: String]) async throws -> SupabaseSession {
        var request = URLRequest(url: baseURL.appending(path: path))
        request.httpMethod = "POST"
        applyBaseHeaders(to: &request)
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let data = try await checkedData(for: request)
        return try decoder.decode(SupabaseSession.self, from: data)
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
        return try decoder.decode(Response.self, from: data)
    }

    private func checkedData(for request: URLRequest) async throws -> Data {
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw SupabaseClientError.invalidResponse }
        guard (200..<300).contains(http.statusCode) else {
            throw SupabaseClientError.requestFailed(http.statusCode, String(data: data, encoding: .utf8) ?? "")
        }
        return data
    }

    private func applyBaseHeaders(to request: inout URLRequest) {
        request.setValue(publishableKey, forHTTPHeaderField: "apikey")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
    }
}

private struct AnyEncodable: Encodable {
    private let encodeClosure: (Encoder) throws -> Void

    init(_ wrapped: Encodable) {
        encodeClosure = wrapped.encode(to:)
    }

    func encode(to encoder: Encoder) throws {
        try encodeClosure(encoder)
    }
}
