import Foundation

@MainActor
final class AuthSessionStore: ObservableObject {
    @Published private(set) var session: SupabaseSession?
    @Published var lastError: String?
    @Published var isWorking = false

    private let client: SupabaseClient
    private let keychain = KeychainSessionStore()
    private let appleSignIn = SignInWithAppleService()

    var isAuthenticated: Bool { session != nil }
    var accessToken: String? { session?.accessToken }
    var userID: UUID? { session?.user.id }
    var email: String? { session?.user.email }

    init(client: SupabaseClient = SupabaseClient()) {
        self.client = client
        session = keychain.load()
        UserDefaults.standard.removeObject(forKey: "questbond.supabase.session.v1")
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

    func signInWithApple() async {
        await performAuthAction {
            let identity = try await appleSignIn.requestIdentityToken()
            session = try await client.signInWithApple(idToken: identity.idToken, nonce: identity.nonce, fullName: identity.fullName)
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
        keychain.clear()
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
        guard let session else { return }
        do {
            try keychain.save(session)
        } catch {
            lastError = error.localizedDescription
        }
    }
}
