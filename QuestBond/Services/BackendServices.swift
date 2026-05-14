import Foundation

enum BackendConfiguration {
    static let supabaseURLPlaceholder = "https://<project-ref>.supabase.co"
    static let publishableKeyPlaceholder = "sb_publishable_<key>"
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
    static let requiredPackage = "https://github.com/supabase/supabase-swift.git"
    static let minimumPackageVersion = "2.0.0"
    static let realtimeChannelPattern = "thread:<thread_id>:messages"
}
