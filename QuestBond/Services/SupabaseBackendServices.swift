import Foundation

final class SupabaseAuthService: AuthServicing {
    private let client: SupabaseClient
    private(set) var currentSession: SupabaseSession?

    var currentUserID: UUID? { currentSession?.user.id }

    init(client: SupabaseClient = SupabaseClient()) {
        self.client = client
    }

    func signInWithApple() async throws {
        throw SupabaseClientError.requestFailed(501, "Sign in with Apple requires Apple Developer configuration before enabling in Supabase Auth.")
    }

    func signIn(email: String, password: String) async throws {
        currentSession = try await client.signIn(email: email, password: password)
    }

    func signUp(email: String, password: String) async throws {
        currentSession = try await client.signUp(email: email, password: password)
    }

    func signOut() async throws {
        currentSession = nil
    }

    func deleteAccount() async throws {
        throw SupabaseClientError.requestFailed(501, "Client-side account deletion needs an authenticated Edge Function or server action with service-role access.")
    }
}

final class SupabaseQuestBondRepository {
    private let client: SupabaseClient
    private let accessTokenProvider: () -> String?

    init(client: SupabaseClient = SupabaseClient(), accessTokenProvider: @escaping () -> String?) {
        self.client = client
        self.accessTokenProvider = accessTokenProvider
    }

    func loadProfile() async throws -> SupabaseProfilePayload {
        try await client.fetchProfile(accessToken: requireAccessToken())
    }

    func loadListings(type: String? = nil) async throws -> [SupabaseListingPayload] {
        try await client.fetchListings(accessToken: requireAccessToken(), listingType: type)
    }

    func save(listing: SupabaseListingPayload) async throws -> SupabaseListingPayload {
        try await client.createListing(listing, accessToken: requireAccessToken())
    }

    private func requireAccessToken() throws -> String {
        guard let accessToken = accessTokenProvider(), !accessToken.isEmpty else {
            throw SupabaseClientError.missingSession
        }
        return accessToken
    }
}
