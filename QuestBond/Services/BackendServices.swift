import Foundation

enum BackendConfiguration {
    static let supabaseURL = SupabaseConfig.url.absoluteString
    static let publishableKeyPrefix = String(SupabaseConfig.publishableKey.prefix(24))
}

protocol AuthServicing {
    var currentUserID: UUID? { get }
    func signInWithApple() async throws
    func signOut() async throws
    func deleteAccount() async throws
}

protocol QuestBondRepository {
    func loadProfile() async throws -> UserProfile
    func loadListings() async throws -> ([GroupListing], [PartyListing])
    func save(group: GroupListing) async throws
    func save(party: PartyListing) async throws
    func send(message: ChatMessage) async throws
    func block(_ block: BlockRecord) async throws
    func report(_ report: ReportRecord) async throws
}

struct LocalAuthService: AuthServicing {
    var currentUserID: UUID?

    func signInWithApple() async throws {}
    func signOut() async throws {}
    func deleteAccount() async throws {}
}

struct SupabaseIntegrationNotes {
    static let projectRef = SupabaseConfig.projectRef
    static let transport = "Supabase REST/Auth APIs via URLSession"
    static let realtimeChannelPattern = "thread:<thread_id>:messages"
}
