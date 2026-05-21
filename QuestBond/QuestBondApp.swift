import SwiftUI

@main
struct QuestBondApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var store = QuestBondStore()
    @StateObject private var auth = AuthSessionStore()
    private let crashReporting = SentryCrashReportingService()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .environmentObject(auth)
                .task {
                    crashReporting.configure()
                    await NotificationRegistrationService.shared.configure()
                    await auth.registerPushTokenIfNeeded(NotificationRegistrationService.shared.deviceToken)
                }
        }
    }
}
