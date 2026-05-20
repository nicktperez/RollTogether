import Foundation

@MainActor
final class AuthSessionStore: ObservableObject {
    @Published private(set) var session: SupabaseSession?
    @Published var lastError: String?
    @Published var isWorking = false

    private let client: SupabaseClient
    private let storageKey = "questbond.supabase.session.v1"

    var isAuthenticated: Bool { session != nil }
    var accessToken: String? { session?.accessToken }
    var userID: UUID? { session?.user.id }
    var email: String? { session?.user.email }

    init(client: SupabaseClient = SupabaseClient()) {
        self.client = client
        if let data = UserDefaults.standard.data(forKey: storageKey) {
            session = try? JSONDecoder().decode(SupabaseSession.self, from: data)
        }
    }

    func signIn(email: String, password: String) async {
        await performAuthAction {
            session = try await client.signIn(email: email, password: password)
            persist()
        }
    }

    func signUp(email: String, password: String, displayName: String) async {
        await performAuthAction {
            session = try await client.signUp(email: email, password: password, displayName: displayName)
            persist()
        }
    }

    func recoverPassword(email: String) async {
        await performAuthAction {
            try await client.recoverPassword(email: email)
            lastError = "Password reset email requested. Check your inbox."
        }
    }

    func signOut() {
        session = nil
        UserDefaults.standard.removeObject(forKey: storageKey)
    }

    func deleteAccount(reason: String) async {
        guard let accessToken else {
            lastError = "Sign in before deleting your account."
            return
        }

        await performAuthAction {
            try await client.deleteAccount(reason: reason, accessToken: accessToken)
            signOut()
        }
    }

    func registerPushTokenIfNeeded(_ token: String?) async {
        guard let token, let userID, let accessToken else { return }
        do {
            try await client.upsertPushToken(
                SupabasePushTokenPayload(userID: userID, platform: "ios", token: token, environment: "development"),
                accessToken: accessToken
            )
        } catch {
            lastError = error.localizedDescription
        }
    }

    private func performAuthAction(_ action: () async throws -> Void) async {
        isWorking = true
        lastError = nil
        do {
            try await action()
        } catch {
            lastError = error.localizedDescription
        }
        isWorking = false
    }

    private func persist() {
        guard let session, let data = try? JSONEncoder().encode(session) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }
}
